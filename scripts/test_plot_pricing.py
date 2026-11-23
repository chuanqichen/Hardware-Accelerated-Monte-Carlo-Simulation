"""Tests for scripts/plot_pricing.py: data extraction, failure on bad inputs, PNG output."""
import contextlib
import csv
import io
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

try:
    import matplotlib  # noqa: F401
    HAVE_MPL = True
except ImportError:
    HAVE_MPL = False

SCRIPTS = Path(__file__).resolve().parent
ROOT = SCRIPTS.parent
RESULTS = ROOT / "results"
NEEDED = ("pricing_accuracy_vs_area.csv", "pricing_ppa_configs.csv", "price_dp_ppa.csv", "accumulator_ppa.csv")
FIGS = ("pricing_exp_table_tradeoff.png", "pricing_lane_scaling.png", "pricing_area_vs_clock.png")

if HAVE_MPL:
    sys.path.insert(0, str(SCRIPTS))
    import plot_pricing as pp


def copy_results(dst: Path, edit=None) -> Path:
    """Copy the needed CSVs to dst; edit(name, rows) may return a modified row list for a file."""
    dst.mkdir(parents=True, exist_ok=True)
    for name in NEEDED:
        with (RESULTS / name).open(newline="") as f:
            rd = csv.DictReader(f)
            fields, rows = rd.fieldnames, list(rd)
        if edit:
            rows = edit(name, rows) or rows
        with (dst / name).open("w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=fields)
            w.writeheader()
            w.writerows(rows)
    return dst


def run_main(results: Path, out: Path):
    err = io.StringIO()
    with contextlib.redirect_stderr(err), contextlib.redirect_stdout(io.StringIO()):
        code = pp.main(["--results-dir", str(results), "--out-dir", str(out)])
    return code, err.getvalue()


@unittest.skipUnless(HAVE_MPL, "matplotlib not installed")
class TestPlotPricing(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)

    def test_extract_shapes(self):
        exp = pp.extract_exp_tradeoff(RESULTS)
        self.assertEqual(len(exp["area_k"]), 3)
        self.assertEqual(len(exp["delta_pct"]), 3)
        self.assertEqual(sorted(exp["bias"]), [8, 10, 12])
        self.assertTrue(all(len(v) == 3 for v in exp["bias"].values()))
        self.assertAlmostEqual(exp["delta_pct"][exp["k"].index(pp.BASE_K)], 0.0)

        lanes = pp.extract_lane_scaling(RESULTS)
        self.assertEqual(len(lanes["total"]), 3)
        self.assertAlmostEqual(lanes["ratio"][0], 1.0)
        for t, a, b in zip(lanes["total"], lanes["price_dp"], lanes["accumulator"]):
            self.assertAlmostEqual(t, a + b)

        clock = pp.extract_clock(RESULTS)
        self.assertEqual([len(s["index"]) for s in clock["series"]], [4, 4, 3])
        for s in clock["series"]:
            self.assertAlmostEqual(s["index"][0], 100.0)
            self.assertTrue(all(w >= 0 for w in s["wns"]))

    def test_clock_title_follows_data(self):
        clock = pp.extract_clock(RESULTS)
        self.assertIn("a few percent", pp.clock_title(clock))
        big = dict(clock, max_increase_pct=17.4)
        self.assertIn("17%", pp.clock_title(big))
        self.assertNotIn("a few percent", pp.clock_title(big))

    def test_script_writes_three_pngs(self):
        out = self.tmp / "figs"
        r = subprocess.run([sys.executable, str(SCRIPTS / "plot_pricing.py"), "--out-dir", str(out)],
                           cwd=str(self.tmp), capture_output=True, text=True, timeout=60)
        self.assertEqual(r.returncode, 0, r.stderr)
        for name in FIGS:
            p = out / name
            self.assertTrue(p.exists() and p.stat().st_size > 5000, name)
            self.assertEqual(p.read_bytes()[:8], b"\x89PNG\r\n\x1a\n")
        self.assertIn("Figure 3", r.stdout)

    def test_missing_row_fails_without_writing(self):
        cases = {
            "pricing_accuracy_vs_area.csv": lambda rows: [r for r in rows if not (r["gauss_addr_bits"] == "12" and r["exp_addr_bits"] == "8")],
            "pricing_ppa_configs.csv": lambda rows: [r for r in rows if r["config"] != "B"],
            "price_dp_ppa.csv": lambda rows: [r for r in rows if r["tag"] != "u1_p450_price_dp_k8_m1_r0"],
            "accumulator_ppa.csv": lambda rows: [r for r in rows if r["tag"] != "v2_p400_accumulator_l4"],
        }
        for name, drop in cases.items():
            with self.subTest(name):
                res = copy_results(self.tmp / ("res_" + name), lambda n, rows, name=name, drop=drop: drop(rows) if n == name else None)
                out = self.tmp / ("out_" + name)
                code, err = run_main(res, out)
                self.assertNotEqual(code, 0)
                self.assertIn("error", err)
                self.assertFalse(out.exists() and any(out.iterdir()))

    def test_duplicate_row_fails(self):
        def dup(name, rows):
            if name == "pricing_accuracy_vs_area.csv":
                return rows + [rows[0]]
        res = copy_results(self.tmp / "res_dup", dup)
        out = self.tmp / "out_dup"
        code, err = run_main(res, out)
        self.assertNotEqual(code, 0)
        self.assertIn("exactly one", err)
        self.assertFalse(out.exists() and any(out.iterdir()))

    def test_negative_wns_fails(self):
        def neg(name, rows):
            if name == "price_dp_ppa.csv":
                for r in rows:
                    if r["tag"] == "u1_p400_price_dp_k10_m1_r0":
                        r["wns_ns"] = "-0.01"
                return rows
        res = copy_results(self.tmp / "res_neg", neg)
        out = self.tmp / "out_neg"
        code, err = run_main(res, out)
        self.assertNotEqual(code, 0)
        self.assertIn("negative setup slack", err)
        self.assertFalse(out.exists() and any(out.iterdir()))

    def test_negative_wns_in_unplotted_row_is_ignored(self):
        def neg(name, rows):
            if name == "price_dp_ppa.csv":
                for r in rows:
                    if r["tag"] == "u1_p400_price_dp_k10_m2_r1":     # not a plotted series
                        r["wns_ns"] = "-0.01"
                return rows
        res = copy_results(self.tmp / "res_unplotted", neg)
        pp.extract_clock(res)


if __name__ == "__main__":
    unittest.main()
