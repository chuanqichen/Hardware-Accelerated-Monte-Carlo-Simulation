"""Pricing-datapath figures for the final report and slides (exp table, lane scaling, clock sweep).

Reads only existing result CSVs, nothing typed by hand:
  - results/pricing_accuracy_vs_area.csv  worst |price bias| vs Black-Scholes and price_dp area,
                                          per (gauss_addr_bits g, exp_addr_bits k)
  - results/pricing_ppa_configs.csv       configs A/B/C (1/2/4 lanes): price_dp and accumulator area
  - results/price_dp_ppa.csv              price_dp synthesis at several clock periods
  - results/accumulator_ppa.csv           accumulator synthesis at several clock periods

    python3 scripts/plot_pricing.py [--out-dir docs/figures] [--results-dir results]
Writes docs/figures/pricing_exp_table_tradeoff.png, pricing_lane_scaling.png and
pricing_area_vs_clock.png, and prints the plotted numbers of each figure as a text table.
A missing or duplicated expected row, or a plotted synthesis row with negative setup slack,
is an error: the script exits non-zero and writes nothing.
"""
from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]

# Structure of the study (which rows to plot), not data.
GAUSS_BITS = (8, 10, 12)
EXP_BITS = (8, 10, 12)
BASE_K = 10                  # exp table size the area deltas are quoted against
CFG_GAUSS_BITS = 10          # configs A/B/C use g = 10; D/E vary g and are not lane scaling
LANES = (1, 2, 4)
BASE_PERIOD = 5.0
DP_PERIODS = (5.0, 4.75, 4.5, 4.0)
ACC_PERIODS = (5.0, 4.75, 4.0)
FEW_PCT = 10.0               # "a few percent" ceiling for the clock figure title

BLUE, RED, AQUA, GREY, REF = "#4c72b0", "#c44e52", "#1baf7a", "#bbbbbb", "#999999"
INK, INK2 = "#222222", "#555555"
MARKERS = ("o", "s", "^")
G_COLOR = {8: RED, 10: BLUE, 12: AQUA}
G_MARK = {8: "o", 10: "s", 12: "^"}
FIGS = ("pricing_exp_table_tradeoff.png", "pricing_lane_scaling.png", "pricing_area_vs_clock.png")


class DataError(Exception):
    """A results file does not contain exactly the rows the figures need."""


# ---------------------------------------------------------------- data extraction

def read_rows(path: Path) -> list[dict]:
    if not path.exists():
        raise DataError(f"missing results file: {path}")
    with path.open(newline="") as f:
        return list(csv.DictReader(f))


def _num(row: dict, col: str, src: str) -> float:
    try:
        return float(row[col])
    except (KeyError, ValueError, TypeError):
        raise DataError(f"{src}: column {col!r} missing or not numeric in {row.get('tag') or row}")


def _one(rows: list[dict], what: str, src: str) -> dict:
    if len(rows) != 1:
        raise DataError(f"{src}: expected exactly one row for {what}, found {len(rows)}")
    return rows[0]


def extract_exp_tradeoff(results_dir: Path) -> dict:
    """Area per k (left panel) and worst |bias| per (g, k) (right panel)."""
    src = "pricing_accuracy_vs_area.csv"
    rows = read_rows(Path(results_dir) / src)
    bias, area = {}, {}
    for g in GAUSS_BITS:
        for k in EXP_BITS:
            r = _one([r for r in rows if r.get("gauss_addr_bits") == str(g) and r.get("exp_addr_bits") == str(k)],
                     f"g={g}, k={k}", src)
            bias[(g, k)] = _num(r, "max_abs_bias_bs_pct", src)
            a = _num(r, "price_dp_area_um2", src)
            if k in area and abs(area[k] - a) > 1e-6:
                raise DataError(f"{src}: price_dp_area_um2 differs across g for k={k}")
            area[k] = a
    base = area[BASE_K]
    return {"k": list(EXP_BITS), "area_k": [area[k] / 1e3 for k in EXP_BITS],
            "delta_pct": [100 * (area[k] - base) / base for k in EXP_BITS],
            "g": list(GAUSS_BITS), "bias": {g: [bias[(g, k)] for k in EXP_BITS] for g in GAUSS_BITS}}


def extract_lane_scaling(results_dir: Path) -> dict:
    src = "pricing_ppa_configs.csv"
    rows = read_rows(Path(results_dir) / src)
    dp, acc = [], []
    for n in LANES:
        r = _one([r for r in rows if r.get("lanes") == str(n) and r.get("gauss_addr_bits") == str(CFG_GAUSS_BITS)],
                 f"lanes={n}, gauss_addr_bits={CFG_GAUSS_BITS}", src)
        dp.append(_num(r, "price_dp_area_um2_total", src) / 1e3)
        acc.append(_num(r, "accumulator_area_um2", src) / 1e3)
        tot = _num(r, "pricing_area_um2_total", src) / 1e3
        if abs(tot - dp[-1] - acc[-1]) > 1e-3:
            raise DataError(f"{src}: pricing_area_um2_total != price_dp + accumulator for lanes={n}")
    total = [a + b for a, b in zip(dp, acc)]
    return {"lanes": list(LANES), "price_dp": dp, "accumulator": acc, "total": total,
            "ratio": [t / total[0] for t in total]}


def _series(results_dir: Path, csv_name: str, tag_re: str, periods: tuple, label: str) -> dict:
    """Area indexed to the 5 ns row of the same block, plus raw area and slack per period."""
    rows = read_rows(Path(results_dir) / csv_name)
    rx = re.compile(tag_re)
    area, wns = {}, {}
    for p in periods:
        r = _one([r for r in rows if rx.search(r.get("tag", "")) and abs(_num(r, "clk_period_ns", csv_name) - p) < 1e-6],
                 f"{label} at {p} ns", csv_name)
        area[p] = _num(r, "area_um2", csv_name)
        wns[p] = _num(r, "wns_ns", csv_name)
        if wns[p] < 0:
            raise DataError(f"{csv_name}: {label} at {p} ns has negative setup slack (wns_ns={wns[p]})")
    return {"label": label, "period": list(periods), "area": [area[p] for p in periods],
            "wns": [wns[p] for p in periods],
            "index": [100 * area[p] / area[BASE_PERIOD] for p in periods]}


def extract_clock(results_dir: Path) -> dict:
    series = [
        _series(results_dir, "price_dp_ppa.csv", r"_price_dp_k10_m1_r0$", DP_PERIODS, "price_dp, k=10"),
        _series(results_dir, "price_dp_ppa.csv", r"_price_dp_k8_m1_r0$", DP_PERIODS, "price_dp, k=8"),
        _series(results_dir, "accumulator_ppa.csv", r"_accumulator_l4$", ACC_PERIODS, "accumulator, 4 lanes"),
    ]
    max_inc = max(max(s["index"]) - 100 for s in series)
    shorter = 100 * (1 - min(DP_PERIODS) / max(DP_PERIODS))
    return {"series": series, "max_increase_pct": max_inc, "period_cut_pct": shorter}


def clock_title(clock: dict) -> str:
    cut = f"{clock['period_cut_pct']:.0f}%"
    if clock["max_increase_pct"] <= FEW_PCT:
        return f"A {cut} shorter clock period costs a few percent of area"
    return f"A {cut} shorter clock period costs up to {clock['max_increase_pct']:.0f}% area"


# ---------------------------------------------------------------- plotting

def style(ax, grid_axis="both"):
    ax.grid(alpha=0.3, axis=grid_axis, which="both" if grid_axis != "y" else "major")
    ax.set_axisbelow(True)
    for s in ("top", "right"):
        ax.spines[s].set_visible(False)
    for s in ("left", "bottom"):
        ax.spines[s].set_color("#888888")
    ax.tick_params(colors=INK2, labelsize=8)
    ax.xaxis.label.set_color(INK)
    ax.yaxis.label.set_color(INK)


def plot_exp_table(d: dict):
    fig, (a1, a2) = plt.subplots(1, 2, figsize=(10.5, 4.0))
    x = range(len(d["k"]))
    labels = [f"k={k}" for k in d["k"]]
    a1.bar(x, d["area_k"], color=BLUE, width=0.6, edgecolor="white", linewidth=1.5)
    for i, (v, dp) in enumerate(zip(d["area_k"], d["delta_pct"])):
        note = "baseline" if d["k"][i] == BASE_K else f"{dp:+.0f}%"
        a1.text(i, v + max(d["area_k"]) * 0.02, f"{v:.1f}", ha="center", va="bottom", fontsize=9, color=INK)
        a1.text(i, v + max(d["area_k"]) * 0.095, note, ha="center", va="bottom", fontsize=8, color=INK2)
    a1.set_xticks(list(x)); a1.set_xticklabels(labels)
    a1.set_ylim(0, max(d["area_k"]) * 1.25)
    a1.set_ylabel("price_dp area at 5 ns [10^3 um^2]")
    a1.set_title("Exp table size sets price_dp area", fontsize=10, color=INK)
    style(a1, "y")

    for g in d["g"]:
        a2.plot(x, d["bias"][g], marker=G_MARK[g], color=G_COLOR[g], lw=2, ms=7, label=f"g={g}")
        kb = d["k"].index(BASE_K)
        a2.annotate(f"g={g}: {d['bias'][g][kb]:.2f}%", (x[-1], d["bias"][g][-1]), textcoords="offset points",
                    xytext=(9, 0), va="center", fontsize=8, color=INK)
    a2.axhline(1.0, color=REF, lw=1, ls=":")
    a2.text(0.03, 1.0, "1 % accuracy target", fontsize=8, color=INK2, va="top", ha="left",
            transform=a2.get_yaxis_transform())
    a2.set_yscale("log")
    a2.set_xticks(list(x)); a2.set_xticklabels([str(k) for k in d["k"]])
    a2.set_xlim(-0.3, len(d["k"]) - 1 + 0.9)
    lo = min(min(v) for v in d["bias"].values()); hi = max(max(v) for v in d["bias"].values())
    a2.set_ylim(lo / 1.8, max(hi, 1.0) * 3.2)
    ticks = [t for t in (0.05, 0.1, 0.2, 0.5, 1, 2, 5) if a2.get_ylim()[0] <= t <= a2.get_ylim()[1]]
    a2.set_yticks(ticks); a2.set_yticklabels([f"{t:g}" for t in ticks])
    a2.minorticks_off()
    a2.set_xlabel("exp table address bits k")
    a2.set_ylabel("worst |price bias| vs Black-Scholes [%]")
    a2.set_title("...but accuracy is set by the Gaussian table", fontsize=10, color=INK)
    leg = a2.legend(title="Gaussian table address bits", fontsize=8, title_fontsize=8, ncol=3,
                    loc="upper center", frameon=False)
    for t in leg.get_texts() + [leg.get_title()]:
        t.set_color(INK)
    style(a2)
    fig.tight_layout()
    return fig


def plot_lane_scaling(d: dict):
    fig, ax = plt.subplots(figsize=(5.6, 4.0))
    x = range(len(d["lanes"]))
    ax.bar(x, d["price_dp"], color=BLUE, width=0.6, edgecolor="white", linewidth=1.5, label="price_dp x lanes")
    ax.bar(x, d["accumulator"], bottom=d["price_dp"], color=RED, width=0.6, edgecolor="white", linewidth=1.5,
           label="accumulator (shared)")
    for i in x:
        ax.text(i, d["price_dp"][i] / 2, f"{d['price_dp'][i]:.1f}", ha="center", va="center", fontsize=8, color="white")
        ax.text(i, d["price_dp"][i] + d["accumulator"][i] / 2, f"{d['accumulator'][i]:.1f}", ha="center",
                va="center", fontsize=7, color="white")
        ax.text(i, d["total"][i] + max(d["total"]) * 0.015, f"{d['total'][i]:.1f}  ({d['ratio'][i]:.2f}x)",
                ha="center", va="bottom", fontsize=9, color=INK)
    ax.set_xticks(list(x)); ax.set_xticklabels([f"{n} lane" + ("s" if n > 1 else "") for n in d["lanes"]])
    ax.set_ylim(0, max(d["total"]) * 1.35)
    ax.set_ylabel("area at 5 ns [10^3 um^2]")
    ax.set_title("Pricing area grows slightly slower than lane count", fontsize=10, color=INK)
    leg = ax.legend(fontsize=8, loc="upper left", frameon=False)
    for t in leg.get_texts():
        t.set_color(INK)
    style(ax, "y")
    ax.text(0.5, -0.12, "Sum of standalone block syntheses at 5 ns, not a synthesized multi-lane top",
            transform=ax.transAxes, ha="center", va="top", fontsize=7.5, style="italic", color=INK2)
    fig.tight_layout()
    return fig


def plot_clock(d: dict):
    fig, ax = plt.subplots(figsize=(5.6, 4.0))
    colors = (BLUE, RED, AQUA)
    for s, c, m in zip(d["series"], colors, MARKERS):
        ax.plot(s["period"], s["index"], marker=m, color=c, lw=2, ms=7, label=s["label"])
        ax.annotate(f"{s['index'][-1]:.1f}%", (s["period"][-1], s["index"][-1]), textcoords="offset points",
                    xytext=(9, 0), ha="left", va="center", fontsize=8, color=INK)
    ax.axhline(100, color=REF, lw=1, ls=":")
    periods = sorted({p for s in d["series"] for p in s["period"]}, reverse=True)
    ax.set_xticks(periods)
    ax.set_xticklabels([f"{p:.2f}\n{1000 / p:.0f} MHz" for p in periods])
    tight = min(periods)
    ax.set_xlim(max(periods) + 0.12, tight - 0.45)          # inverted: tighter clocks to the right
    lo = min(min(s["index"]) for s in d["series"]); hi = max(max(s["index"]) for s in d["series"])
    ax.set_ylim(min(98.0, lo - 1), hi + 2.2)
    ax.set_xlabel("clock period [ns]")
    ax.set_ylabel(f"area relative to 5 ns [%]  (axis starts at {ax.get_ylim()[0]:g})")
    ax.set_title(clock_title(d), fontsize=10, color=INK)
    leg = ax.legend(fontsize=8, loc="upper left", frameon=False)
    for t in leg.get_texts():
        t.set_color(INK)
    style(ax)
    ax.text(0.98, 0.04, "all points met setup timing (pre-layout)", transform=ax.transAxes, ha="right",
            va="bottom", fontsize=7.5, style="italic", color=INK2)
    fig.tight_layout()
    return fig


# ---------------------------------------------------------------- text tables

def tables(exp: dict, lanes: dict, clock: dict) -> dict:
    t1 = ["Figure 1: pricing_exp_table_tradeoff",
          "  price_dp area vs exp table size k (change vs k=%d)" % BASE_K,
          f"  {'k':>3} {'area 10^3um2':>13} {'vs k=%d' % BASE_K:>9}"]
    t1 += [f"  {k:>3} {a:>13.2f} {dp:>+8.1f}%" for k, a, dp in zip(exp["k"], exp["area_k"], exp["delta_pct"])]
    t1 += ["  worst |bias| vs Black-Scholes [%]", "  " + f"{'g | k':>6}" + "".join(f"{k:>9}" for k in exp["k"])]
    t1 += ["  " + f"{'g=' + str(g):>6}" + "".join(f"{v:>9.3f}" for v in exp["bias"][g]) for g in exp["g"]]
    t2 = ["Figure 2: pricing_lane_scaling (10^3 um^2, 5 ns)",
          f"  {'lanes':>5} {'price_dp':>9} {'accum':>8} {'total':>8} {'ratio':>7}"]
    t2 += [f"  {n:>5} {a:>9.2f} {b:>8.2f} {c:>8.2f} {r:>6.2f}x" for n, a, b, c, r in
           zip(lanes["lanes"], lanes["price_dp"], lanes["accumulator"], lanes["total"], lanes["ratio"])]
    t3 = ["Figure 3: pricing_area_vs_clock (area indexed to 5 ns = 100)"]
    for s in clock["series"]:
        t3.append(f"  {s['label']}")
        t3.append(f"    {'period ns':>9} {'area um2':>10} {'index %':>8} {'wns ns':>8}")
        t3 += [f"    {p:>9.2f} {a:>10.1f} {i:>8.2f} {w:>8.3f}" for p, a, i, w in
               zip(s["period"], s["area"], s["index"], s["wns"])]
    t3.append(f"  max increase {clock['max_increase_pct']:.2f}%; title: {clock_title(clock)}")
    return {FIGS[0]: "\n".join(t1), FIGS[1]: "\n".join(t2), FIGS[2]: "\n".join(t3)}


# ---------------------------------------------------------------- main

def resolve(p: str) -> Path:
    p = Path(p)
    return p if p.is_absolute() else ROOT / p


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--out-dir", default="docs/figures", help="figure directory (relative to the repo root)")
    ap.add_argument("--results-dir", default="results", help="results directory (relative to the repo root)")
    a = ap.parse_args(argv)
    out_dir, res = resolve(a.out_dir), resolve(a.results_dir)

    try:                                                    # validate everything before writing anything
        exp = extract_exp_tradeoff(res)
        lanes = extract_lane_scaling(res)
        clock = extract_clock(res)
    except DataError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1

    out_dir.mkdir(parents=True, exist_ok=True)
    txt = tables(exp, lanes, clock)
    for name, fig in zip(FIGS, (plot_exp_table(exp), plot_lane_scaling(lanes), plot_clock(clock))):
        fig.savefig(out_dir / name, dpi=200, bbox_inches="tight", metadata={"Software": None})
        plt.close(fig)
        print(txt[name], f"\n  wrote {out_dir / name}\n", sep="")
    return 0


if __name__ == "__main__":
    sys.exit(main())
