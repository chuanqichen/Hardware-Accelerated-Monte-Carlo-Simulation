"""Unit tests for the pricing accuracy-vs-area study.  Run: make test"""
import csv
import math
import tempfile
import unittest
from pathlib import Path

import pricing_tradeoff as pt

ROOT = Path(__file__).resolve().parents[1]
PPA = ROOT / "results" / "price_dp_ppa.csv"
ACC_PPA = ROOT / "results" / "accumulator_ppa.csv"

# python3 model/price_dp.py sweep table (Gaussian table 10 bits), percent
DP_ANCHOR = {8: [0.0135, 0.0228, 0.0182, -0.0250, -0.0259],
             10: [0.0160, 0.0242, 0.0138, -0.0355, -0.0504]}
BS_ANCHOR_10 = [0.002, -0.009, -0.094, -0.190, -0.381]


class TestPricingTradeoff(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.out = Path(cls.tmp.name) / "run1"
        cls.acc, cls.cfgs = pt.run(PPA, ACC_PPA, cls.out, quiet=True)
        cls.by_gk = {(r["gauss_addr_bits"], r["exp_addr_bits"]): r for r in cls.acc}
        cls.by_cfg = {r["config"]: r for r in cls.cfgs}

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def test_grid_shape_and_order(self):
        self.assertEqual([(r["gauss_addr_bits"], r["exp_addr_bits"]) for r in self.acc],
                         [(g, k) for g in (8, 10, 12) for k in (8, 10, 12)])
        self.assertEqual(pt.OPT_SUFFIXES,
                         ["itm80_s02", "atm100_s02", "otm120_s02", "atm100_s06", "otm150_s06"])

    def test_price_dp_alone_bias_matches_price_dp_sweep(self):
        for k, want in DP_ANCHOR.items():
            row = self.by_gk[(10, k)]
            for suf, w in zip(pt.OPT_SUFFIXES, want):
                self.assertAlmostEqual(row[f"bias_dp_pct_{suf}"], w, delta=5e-4, msg=(k, suf))

    def test_end_to_end_bias_matches_price_dp_demo(self):
        row = self.by_gk[(10, 10)]
        for suf, w in zip(pt.OPT_SUFFIXES, BS_ANCHOR_10):
            self.assertAlmostEqual(row[f"bias_bs_pct_{suf}"], w, delta=1e-3, msg=suf)

    def test_max_abs_columns(self):
        for r in self.acc:
            self.assertEqual(r["max_abs_bias_dp_pct"],
                             max(abs(r[f"bias_dp_pct_{s}"]) for s in pt.OPT_SUFFIXES))
            self.assertEqual(r["max_abs_bias_bs_pct"],
                             max(abs(r[f"bias_bs_pct_{s}"]) for s in pt.OPT_SUFFIXES))

    def test_synthesis_columns_come_from_k_row(self):
        for r in self.acc:
            self.assertTrue(r["price_dp_area_tag"].endswith(f"_k{r['exp_addr_bits']}_m1_r0"))
        self.assertEqual(self.by_gk[(8, 10)]["price_dp_area_um2"], self.by_gk[(12, 10)]["price_dp_area_um2"])

    def test_config_table(self):
        self.assertEqual([r["config"] for r in self.cfgs], list("ABCDE"))
        self.assertEqual([(r["lanes"], r["gauss_addr_bits"]) for r in self.cfgs],
                         [(1, 10), (2, 10), (4, 10), (1, 8), (1, 12)])
        c = self.by_cfg["C"]
        for col, conv in (("area_um2", float), ("registers", int), ("power_mw", float)):
            each, acc = conv(c[f"price_dp_{col}_each"]), conv(c[f"accumulator_{col}"])
            self.assertAlmostEqual(c[f"price_dp_{col}_total"], 4 * each, places=6)
            self.assertAlmostEqual(c[f"pricing_{col}_total"], 4 * each + acc, places=6)
        self.assertEqual(c["source_tags"], "u1a_price_dp_k10_m1_r0;v2_p500_accumulator_l4")
        self.assertEqual([r["lat_acc_cycles"] for r in self.cfgs], [1, 2, 3, 1, 1])
        self.assertEqual({r["lat_dp_cycles"] for r in self.cfgs}, {6})
        self.assertEqual([r["trials_per_cycle"] for r in self.cfgs], [1, 2, 4, 1, 1])
        self.assertEqual(self.by_cfg["B"]["trials_per_s_at_200mhz"], 400e6)
        for r in self.cfgs:
            self.assertEqual(r["max_abs_bias_bs_pct"], self.by_gk[(r["gauss_addr_bits"], 10)]["max_abs_bias_bs_pct"])
            self.assertEqual(r["basis"], pt.BASIS)

    def test_csv_files_written(self):
        with (self.out / "pricing_ppa_configs.csv").open(newline="") as f:
            rows = list(csv.DictReader(f))
        self.assertEqual(len(rows), 5)
        with (self.out / "pricing_accuracy_vs_area.csv").open(newline="") as f:
            self.assertEqual(len(list(csv.DictReader(f))), 9)

    def test_throughput_rows_and_periods(self):
        with (self.out / "pricing_throughput.csv").open(newline="") as f:
            rows = list(csv.DictReader(f))
        self.assertEqual({(int(r["lanes"]), float(r["clk_period_ns"])) for r in rows},
                         {(l, p) for l in (1, 2, 4) for p in (5.0, 4.75, 4.0)})    # 4.5 ns: price_dp only
        self.assertEqual(len(rows), 9)
        for r in rows:
            lanes, period = int(r["lanes"]), float(r["clk_period_ns"])
            self.assertAlmostEqual(float(r["clk_mhz"]), 1000.0 / period, places=5)
            self.assertAlmostEqual(float(r["trials_per_s"]), lanes * 1e9 / period, delta=1e-3)
            self.assertEqual(r["both_met"], "true")
            self.assertEqual(r["basis"], "pre-layout standalone block synthesis; II=1 per lane from RTL simulation")
            self.assertTrue(r["price_dp_tag"].endswith("_price_dp_k10_m1_r0"))
            self.assertTrue(r["accumulator_tag"].endswith(f"_accumulator_l{lanes}"))
        five = {int(r["lanes"]): r for r in rows if float(r["clk_period_ns"]) == 5.0}
        self.assertEqual(five[1]["trials_per_s"], "200000000")
        self.assertEqual(five[4]["trials_per_s"], "800000000")
        self.assertEqual(five[2]["price_dp_tag"], "u1a_price_dp_k10_m1_r0")
        self.assertEqual(five[2]["accumulator_tag"], "v2_p500_accumulator_l2")
        self.assertEqual(five[2]["accumulator_wns_ns"], "0.891502")         # source string kept

    def test_throughput_both_met_follows_slack(self):
        dp, acc = pt.read_csv(PPA), pt.read_csv(ACC_PPA)
        for r in acc:
            if r["tag"] == "v2_p400_accumulator_l2":
                r["wns_ns"] = "-0.01"
        rows = pt.throughput_rows(dp, acc)
        met = {(r["lanes"], r["clk_period_ns"]): r["both_met"] for r in rows}
        self.assertEqual(met[(2, 4.0)], "false")
        self.assertEqual(sum(v == "true" for v in met.values()), 8)

    def test_missing_row_is_an_error(self):
        with PPA.open(newline="") as f:
            rd = csv.DictReader(f)
            rows = [r for r in rd if not r["tag"].endswith("_k8_m1_r0") or r["tag"].startswith("u1_")]
            cols = rd.fieldnames
        with tempfile.TemporaryDirectory() as d:
            bad = Path(d) / "ppa.csv"
            with bad.open("w", newline="") as f:
                w = csv.DictWriter(f, fieldnames=cols)
                w.writeheader()
                w.writerows(rows)
            with self.assertRaises(pt.PpaError):
                pt.run(bad, ACC_PPA, Path(d) / "out", quiet=True)
            self.assertNotEqual(pt.main(["--ppa", str(bad), "--acc-ppa", str(ACC_PPA),
                                         "--out-dir", str(Path(d) / "out")]), 0)
            self.assertFalse((Path(d) / "out").exists())

    def test_ambiguous_row_is_an_error(self):
        rows = pt.read_csv(PPA)
        dup = [r for r in rows if r["tag"] == "u1a_price_dp_k10_m1_r0"][0]
        with self.assertRaises(pt.PpaError):
            pt.select_price_dp(rows + [dict(dup, tag="other_k10_m1_r0")], 10)

    def test_deterministic_bytes(self):
        out2 = Path(self.tmp.name) / "run2"
        pt.run(PPA, ACC_PPA, out2, quiet=True)
        for name in ("pricing_accuracy_vs_area.csv", "pricing_ppa_configs.csv", "pricing_throughput.csv"):
            self.assertEqual((self.out / name).read_bytes(), (out2 / name).read_bytes())


if __name__ == "__main__":
    unittest.main()
