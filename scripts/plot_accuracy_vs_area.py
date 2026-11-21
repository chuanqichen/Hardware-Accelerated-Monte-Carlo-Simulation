"""Accuracy-versus-area tradeoff figure for the Gaussian table size (weekly-plan configs D/A/E).

Joins three sources, nothing typed by hand:
  - exact price bias per ADDR_BITS from the bit-accurate model (model/gauss_lut.py +
    model/price_dp.py, every table output enumerated - no Monte Carlo noise)
  - gauss_lut standalone PPA        results/gauss_lut_ppa.csv       (scripts/syn/run_sweep.sh)
  - whole one-lane mc_top PPA       results/lane_addr_bits_ppa.csv  (scripts/syn/run_lane_sweep.sh)

    python3 scripts/plot_accuracy_vs_area.py
Writes docs/figures/accuracy_vs_area.png and results/accuracy_vs_area.csv.
"""
from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "model"))
import price_dp as pd                                   # noqa: E402
from gauss_lut import OPTION_GRID, GaussLut, GaussLutConfig, bs_call   # noqa: E402

ADDR_BITS = (8, 10, 12)


def model_bias(a: int) -> dict:
    """Exact bias vs Black-Scholes for every grid option, and the worst/ATM cases."""
    lut = GaussLut(GaussLutConfig(a, 16, 12))
    cfg = pd.PriceDpConfig()
    out = {}
    for label, *opt in OPTION_GRID:
        bs = bs_call(*opt)
        out[label] = 100 * (pd.exact_price(*opt, cfg, lut) - bs) / bs
    out["worst_abs"] = max(abs(v) for v in out.values())
    out["atm"] = out["ATM  K=100 s=0.2"]
    return out


def read_ppa(path: Path, tag_re: str) -> dict[int, dict]:
    rows = {}
    if not path.exists():
        return rows
    for r in csv.DictReader(path.open()):
        m = re.search(tag_re, r["tag"])
        if m:
            rows[int(m.group(1))] = r
    return rows


def main():
    lut_ppa = read_ppa(ROOT / "results" / "gauss_lut_ppa.csv", r"gauss_lut_a(\d+)_w16_l1$")
    lane_ppa = read_ppa(ROOT / "results" / "lane_addr_bits_ppa.csv", r"mc_top_a(\d+)_k10$")
    rows = []
    for a in ADDR_BITS:
        b = model_bias(a)
        r = dict(addr_bits=a, rom_bits=(1 << (a - 1)) * 16,
                 bias_worst_pct=b["worst_abs"], bias_atm_pct=b["atm"],
                 **{f"bias_{k.split()[0].lower()}_{k.split()[1][2:]}_{k.split()[2][2:]}_pct": v
                    for k, v in b.items() if k not in ("worst_abs", "atm")})
        if a in lut_ppa:
            r.update(lut_area_um2=float(lut_ppa[a]["area_um2"]), lut_power_mw=float(lut_ppa[a]["power_total_mw"]))
        if a in lane_ppa:
            r.update(lane_area_um2=float(lane_ppa[a]["area_um2"]), lane_power_mw=float(lane_ppa[a]["power_total_mw"]),
                     lane_wns_ns=float(lane_ppa[a]["wns_ns"]))
        rows.append(r)

    out_csv = ROOT / "results" / "accuracy_vs_area.csv"
    keys = sorted({k for r in rows for k in r}, key=lambda k: (k != "addr_bits", k))
    with out_csv.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=keys); w.writeheader(); w.writerows(rows)

    fig, (a1, a2) = plt.subplots(1, 2, figsize=(10.5, 4.0))
    have_lane = all("lane_area_um2" in r for r in rows)
    x = [r["lane_area_um2"] / 1e3 if have_lane else r["lut_area_um2"] / 1e3 for r in rows]
    a1.plot(x, [r["bias_worst_pct"] for r in rows], "o-", color="#c44e52", label="worst grid case (OTM K=150, sigma=0.6)")
    a1.plot(x, [abs(r["bias_atm_pct"]) for r in rows], "s--", color="#4c72b0", label="ATM K=100, sigma=0.2")
    for r, xi in zip(rows, x):
        a1.annotate(f"a={r['addr_bits']}", (xi, r["bias_worst_pct"]), textcoords="offset points", xytext=(6, 4), fontsize=8)
    a1.axhline(1.0, color="#999", lw=0.8, ls=":"); a1.text(x[0], 1.03, "1 % target", fontsize=7.5, color="#666")
    a1.set_yscale("log")
    a1.set_xlabel("one-lane area [10^3 um^2]" if have_lane else "gauss_lut area [10^3 um^2]")
    a1.set_ylabel("|exact price bias| vs Black-Scholes [%]")
    a1.set_title("Accuracy vs area, Gaussian ADDR_BITS = 8 / 10 / 12", fontsize=10)
    a1.legend(fontsize=7.5); a1.grid(alpha=0.3, which="both")

    labels = [f"a={r['addr_bits']}" for r in rows]
    lut = [r["lut_area_um2"] / 1e3 for r in rows]
    if have_lane:
        rest = [r["lane_area_um2"] / 1e3 - l for r, l in zip(rows, lut)]
        a2.bar(labels, rest, color="#bbb", label="rest of lane (RNG, price_dp, accumulator, control)")
        a2.bar(labels, lut, bottom=rest, color="#4c72b0", label="gauss_lut")
        for i, r in enumerate(rows):
            a2.text(i, r["lane_area_um2"] / 1e3 + 0.4, f"{100 * r['lut_area_um2'] / r['lane_area_um2']:.0f}% LUT",
                    ha="center", fontsize=7.5)
        a2.set_ylabel("area [10^3 um^2]"); a2.set_title("Where the lane area goes", fontsize=10)
    else:
        a2.bar(labels, lut, color="#4c72b0", label="gauss_lut")
        a2.set_ylabel("gauss_lut area [10^3 um^2]"); a2.set_title("LUT area (lane sweep pending)", fontsize=10)
    a2.legend(fontsize=7.5, loc="upper left"); a2.grid(alpha=0.3, axis="y")
    fig.tight_layout()
    out_png = ROOT / "docs" / "figures" / "accuracy_vs_area.png"
    fig.savefig(out_png, dpi=200, bbox_inches="tight"); plt.close(fig)

    print(f"{'a':>3} {'ROM bits':>9} {'worst bias':>11} {'ATM bias':>9} {'LUT um2':>9} {'lane um2':>10} {'LUT %':>6} {'lane mW':>8}")
    for r in rows:
        lane = r.get("lane_area_um2"); lutA = r.get("lut_area_um2")
        print(f"{r['addr_bits']:>3} {r['rom_bits']:>9} {r['bias_worst_pct']:>10.3f}% {r['bias_atm_pct']:>+8.3f}% "
              f"{lutA if lutA else float('nan'):>9.0f} {lane if lane else float('nan'):>10.0f} "
              f"{(100 * lutA / lane) if lane and lutA else float('nan'):>5.1f}% {r.get('lane_power_mw', float('nan')):>8.3f}")
    print(f"wrote {out_csv} and {out_png}")


if __name__ == "__main__":
    main()
