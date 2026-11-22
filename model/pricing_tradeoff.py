"""Pricing-block accuracy vs area study and the five team comparison configurations.

Joins the exact (noise-free) price bias of the bit-accurate model with the standalone
synthesis results of price_dp and the accumulator.

  results/pricing_accuracy_vs_area.csv
      one row per (Gaussian table bits g, exp table bits k), g and k in {8, 10, 12}:
      exp-table error, per-option price bias (price_dp alone and end to end vs
      Black-Scholes) and the 5 ns / MUL_STAGES=1 / RETIME=0 price_dp area, power, registers.
  results/pricing_ppa_configs.csv
      configurations A-E (1/2/4 lanes, Gaussian table 8/10/12 bits), pricing blocks only:
      N x price_dp + accumulator, summed from the standalone syntheses (not a synthesized
      multi-lane top).
  results/pricing_throughput.csv
      one row per (lanes 1/2/4, clock period) for every period synthesized for both the
      price_dp (k=10, MUL_STAGES=1, RETIME=0) and the accumulator of that lane count:
      both blocks' wns, whether both met timing, and trials per second (lanes / period,
      one trial per lane per clock). Rows are matched by clk_period_ns, not by tag prefix.

Every number comes from price_dp.py / gauss_lut.py or from the input CSVs; the only
constants here are the configuration table and the 200 MHz clock.

    python3 model/pricing_tradeoff.py
"""
from __future__ import annotations

import argparse
import csv
import sys
from functools import lru_cache
from pathlib import Path

import price_dp as pd
from gauss_lut import OPTION_GRID, GaussLut, GaussLutConfig, bs_call

ROOT = Path(__file__).resolve().parents[1]

GAUSS_BITS = (8, 10, 12)
EXP_BITS = (8, 10, 12)
SYN_CLK_NS = 5.0
CLK_HZ = 200e6
MUL_STAGES = 1
BASIS = "sum of standalone block syntheses, not a synthesized multi-lane top"
THROUGHPUT_BASIS = "pre-layout standalone block synthesis; II=1 per lane from RTL simulation"
THROUGHPUT_LANES = (1, 2, 4)
THROUGHPUT_EXP_BITS = 10

# (config, lanes, gauss_addr_bits, purpose); all use exp_addr_bits = EXP_BITS_CONFIGS
CONFIGS = (
    ("A", 1, 10, "Baseline"),
    ("B", 2, 10, "Scaling"),
    ("C", 4, 10, "Scaling"),
    ("D", 1, 8, "Smaller LUT"),
    ("E", 1, 12, "Higher accuracy"),
)
EXP_BITS_CONFIGS = 10


class PpaError(Exception):
    """A needed synthesis row is missing or ambiguous."""


def opt_suffix(label: str) -> str:
    """'ITM  K=80  s=0.2' -> 'itm80_s02'."""
    kind, strike, sigma = label.split()
    return f"{kind.lower()}{strike.split('=')[1]}_s{sigma.split('=')[1].replace('.', '')}"


OPT_SUFFIXES = [opt_suffix(label) for label, *_ in OPTION_GRID]


# ---- model side ----------------------------------------------------------------
@lru_cache(maxsize=None)
def _exp_error(k: int) -> tuple:
    e = pd.exp_error(pd.PriceDpConfig(exp_addr_bits=k))      # exhaustive over every x
    return e["max_rel"], e["mean_rel"]


def _pct(hw: float, ref: float) -> float:
    return 100.0 * (hw - ref) / ref


def accuracy_rows(ppa: dict) -> list:
    """One dict per (g, k). `ppa` maps k -> selected price_dp synthesis row."""
    rows = []
    for g in GAUSS_BITS:
        lut = GaussLut(GaussLutConfig(g, 16, 12))
        for k in EXP_BITS:
            cfg = pd.PriceDpConfig(exp_addr_bits=k, mul_stages=MUL_STAGES)
            max_rel, mean_rel = _exp_error(k)
            row = dict(gauss_addr_bits=g, exp_addr_bits=k,
                       exp_rom_bits=(1 << k) * cfg.rom_width,
                       exp_max_rel_err=max_rel, exp_mean_rel_err=mean_rel)
            dp, bs = [], []
            for (_, *args), suf in zip(OPTION_GRID, OPT_SUFFIXES):
                hw = pd.exact_price(*args, cfg, lut)
                dp.append(_pct(hw, lut.exact_call_price(*args)))   # same z, float math
                bs.append(_pct(hw, bs_call(*args)))                # end to end
            for suf, v in zip(OPT_SUFFIXES, dp):
                row[f"bias_dp_pct_{suf}"] = v
            for suf, v in zip(OPT_SUFFIXES, bs):
                row[f"bias_bs_pct_{suf}"] = v
            row["max_abs_bias_dp_pct"] = max(abs(v) for v in dp)
            row["max_abs_bias_bs_pct"] = max(abs(v) for v in bs)
            src = ppa[k]
            row["price_dp_area_um2"] = src["area_um2"]
            row["price_dp_power_mw"] = src["power_total_mw"]
            row["price_dp_registers"] = src["registers"]
            row["price_dp_area_tag"] = src["tag"]
            rows.append(row)
    return rows


# ---- synthesis side --------------------------------------------------------------
def read_csv(path: Path) -> list:
    path = Path(path)
    if not path.is_file():
        raise PpaError(f"synthesis CSV not found: {path}")
    with path.open(newline="") as f:
        return list(csv.DictReader(f))


def _unique(rows: list, what: str, path) -> dict:
    if len(rows) != 1:
        raise PpaError(f"{what}: expected exactly one row in {path}, found {len(rows)}"
                       + (f" ({', '.join(r['tag'] for r in rows)})" if rows else ""))
    return rows[0]


def select_price_dp(rows: list, k: int, path="price_dp_ppa.csv") -> dict:
    """The 5.0 ns, MUL_STAGES=1, RETIME=0 row for exp_addr_bits=k."""
    match = [r for r in rows
             if r["tag"].endswith(f"_k{k}_m{MUL_STAGES}_r0")
             and abs(float(r["clk_period_ns"]) - SYN_CLK_NS) < 1e-9]
    return _unique(match, f"price_dp k={k} m{MUL_STAGES} r0 at {SYN_CLK_NS} ns", path)


def select_accumulator(rows: list, lanes: int, path="accumulator_ppa.csv") -> dict:
    """The 5.0 ns row for this lane count (tag ends _accumulator_l<lanes>)."""
    suffix = f"_accumulator_l{lanes}"
    match = [r for r in rows
             if r["tag"].endswith(suffix) and abs(float(r["clk_period_ns"]) - SYN_CLK_NS) < 1e-9]
    return _unique(match, f"accumulator {suffix} at {SYN_CLK_NS} ns", path)


def config_rows(acc: list, dp_ppa: dict, acc_ppa: dict) -> list:
    """Configurations A-E. `acc` = accuracy rows; dp_ppa: k -> row; acc_ppa: lanes -> row."""
    by_gk = {(r["gauss_addr_bits"], r["exp_addr_bits"]): r for r in acc}
    cfg = pd.PriceDpConfig(exp_addr_bits=EXP_BITS_CONFIGS, mul_stages=MUL_STAGES)
    rows = []
    for name, lanes, g, purpose in CONFIGS:
        dp, ac = dp_ppa[EXP_BITS_CONFIGS], acc_ppa[lanes]
        row = dict(config=name, lanes=lanes, gauss_addr_bits=g, exp_addr_bits=EXP_BITS_CONFIGS,
                   purpose=purpose)
        for key, col, conv in (("area_um2", "area_um2", float), ("registers", "registers", int),
                               ("power_total_mw", "power_mw", float)):
            each, acc_v = conv(dp[key]), conv(ac[key])
            row[f"price_dp_{col}_each"] = dp[key]            # as in the source CSV
            row[f"price_dp_{col}_total"] = each * lanes
            row[f"accumulator_{col}"] = ac[key]
            row[f"pricing_{col}_total"] = each * lanes + acc_v
        row["power_activity"] = ";".join(sorted({dp["power_activity"], ac["power_activity"]}))
        row["lat_dp_cycles"] = cfg.lat_dp
        row["lat_acc_cycles"] = 1 + (lanes - 1).bit_length()
        row["trials_per_cycle"] = lanes
        row["trials_per_s_at_200mhz"] = lanes * CLK_HZ
        row["max_abs_bias_bs_pct"] = by_gk[(g, EXP_BITS_CONFIGS)]["max_abs_bias_bs_pct"]
        row["source_tags"] = f"{dp['tag']};{ac['tag']}"
        row["basis"] = BASIS
        rows.append(row)
    return rows


def _by_period(rows: list, suffix: str, what: str, path) -> dict:
    """clk_period_ns (rounded to 1 ps) -> the one row whose tag ends with `suffix`."""
    found = {}
    for r in rows:
        if r["tag"].endswith(suffix):
            found.setdefault(round(float(r["clk_period_ns"]), 3), []).append(r)
    return {p: _unique(rs, f"{what} at {p} ns", path) for p, rs in found.items()}


def throughput_rows(dp_rows: list, acc_rows: list, dp_path="price_dp_ppa.csv",
                    acc_path="accumulator_ppa.csv") -> list:
    """Per lane count and clock period synthesized for both blocks: slack and trials/s."""
    dp = _by_period(dp_rows, f"_price_dp_k{THROUGHPUT_EXP_BITS}_m{MUL_STAGES}_r0",
                    f"price_dp k={THROUGHPUT_EXP_BITS} m{MUL_STAGES} r0", dp_path)
    rows = []
    for lanes in THROUGHPUT_LANES:
        acc = _by_period(acc_rows, f"_accumulator_l{lanes}", f"accumulator l{lanes}", acc_path)
        for period in sorted(dp.keys() & acc.keys(), reverse=True):
            d, a = dp[period], acc[period]
            rows.append(dict(
                lanes=lanes, clk_period_ns=period, clk_mhz=1000.0 / period,
                price_dp_wns_ns=d["wns_ns"], accumulator_wns_ns=a["wns_ns"],
                both_met="true" if float(d["wns_ns"]) >= 0 and float(a["wns_ns"]) >= 0 else "false",
                trials_per_s=lanes * 1e9 / period,
                price_dp_tag=d["tag"], accumulator_tag=a["tag"], basis=THROUGHPUT_BASIS))
    if not rows:
        raise PpaError("no clock period is present for both price_dp and the accumulator")
    return rows


# ---- output ----------------------------------------------------------------------
def fmt(v, col: str = "") -> str:
    """Fixed 6-decimal floats (relative errors in 6-digit scientific); ints and strings as-is."""
    if isinstance(v, float):
        if col.startswith("exp_") and col.endswith("_rel_err"):
            return f"{v:.6e}"
        return f"{v:.0f}" if v.is_integer() and abs(v) >= 1e6 else f"{v:.6f}"
    return str(v)


def write_csv(rows: list, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    cols = list(rows[0])
    with path.open("w", newline="") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(cols)
        for r in rows:
            w.writerow([fmt(r[c], c) for c in cols])


def print_table(rows: list, cols: list, title: str) -> None:
    print(title)
    cells = [[fmt(r[c], c) for c in cols] for r in rows]
    widths = [max(len(c), *(len(row[i]) for row in cells)) for i, c in enumerate(cols)]
    print("  ".join(c.rjust(w) for c, w in zip(cols, widths)))
    for row in cells:
        print("  ".join(v.rjust(w) for v, w in zip(row, widths)))
    print()


def resolve(p: str) -> Path:
    p = Path(p)
    return p if p.is_absolute() else ROOT / p


def run(ppa_path: Path, acc_path: Path, out_dir: Path, quiet: bool = False) -> tuple:
    dp_rows, acc_rows = read_csv(ppa_path), read_csv(acc_path)
    dp_ppa = {k: select_price_dp(dp_rows, k, ppa_path) for k in EXP_BITS}
    acc_ppa = {lanes: select_accumulator(acc_rows, lanes, acc_path) for _, lanes, _, _ in CONFIGS}
    acc = accuracy_rows(dp_ppa)
    cfgs = config_rows(acc, dp_ppa, acc_ppa)
    tput = throughput_rows(dp_rows, acc_rows, ppa_path, acc_path)
    write_csv(acc, out_dir / "pricing_accuracy_vs_area.csv")
    write_csv(cfgs, out_dir / "pricing_ppa_configs.csv")
    write_csv(tput, out_dir / "pricing_throughput.csv")
    if not quiet:
        bias = [f"bias_dp_pct_{s}" for s in OPT_SUFFIXES]
        print_table(acc, ["gauss_addr_bits", "exp_addr_bits", "exp_rom_bits", "exp_max_rel_err"] + bias
                    + ["max_abs_bias_dp_pct"], "price_dp alone: bias vs same Gaussian table, float math (%)")
        bias = [f"bias_bs_pct_{s}" for s in OPT_SUFFIXES]
        print_table(acc, ["gauss_addr_bits", "exp_addr_bits"] + bias + ["max_abs_bias_bs_pct",
                    "price_dp_area_um2", "price_dp_power_mw", "price_dp_registers"],
                    "end to end: bias vs Black-Scholes (%), price_dp 5 ns m1 r0 synthesis")
        print_table(cfgs, ["config", "lanes", "gauss_addr_bits", "price_dp_area_um2_total",
                           "accumulator_area_um2", "pricing_area_um2_total", "pricing_power_mw_total",
                           "pricing_registers_total", "lat_dp_cycles", "lat_acc_cycles",
                           "trials_per_s_at_200mhz", "max_abs_bias_bs_pct"],
                    "pricing configurations (" + BASIS + "; power is " + cfgs[0]["power_activity"] + ")")
        print_table(tput, ["lanes", "clk_period_ns", "clk_mhz", "price_dp_wns_ns", "accumulator_wns_ns",
                           "both_met", "trials_per_s"], "pricing throughput (" + THROUGHPUT_BASIS + ")")
    return acc, cfgs


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--ppa", default="results/price_dp_ppa.csv", help="standalone price_dp synthesis CSV")
    ap.add_argument("--acc-ppa", default="results/accumulator_ppa.csv", help="standalone accumulator CSV")
    ap.add_argument("--out-dir", default="results", help="output directory")
    args = ap.parse_args(argv)
    try:
        run(resolve(args.ppa), resolve(args.acc_ppa), resolve(args.out_dir))
    except PpaError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
