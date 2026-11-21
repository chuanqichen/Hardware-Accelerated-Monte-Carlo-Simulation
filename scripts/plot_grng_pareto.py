"""Bias-vs-area Pareto plot for every Gaussian generator synthesised on the shared flow.

Left: worst-case European-call bias (exact) vs DC area, all generators, K-S annotated to
show it does not predict the ranking. Right: digital-call (K=200) tail bias, where the
uniform ROM returns exactly zero. Data from model/grng_fom.py (+ segmented and CLT models)
and reports/syn/*/summary.txt.

    python3 scripts/plot_grng_pareto.py  -> docs/figures/grng_pareto.png, results/grng_pareto.csv
"""
from __future__ import annotations

import csv
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "model"))
import grng_fom                                   # noqa: E402
from gauss_lut_seg import SegLut, SegLutConfig    # noqa: E402
import clt_grng                                   # noqa: E402
from gauss_lut_pwl import PwlLut, PwlConfig       # noqa: E402


def area(tag):
    for line in (ROOT / "reports" / "syn" / tag / "summary.txt").read_text().splitlines():
        if line.startswith("area_um2"):
            return float(line.split()[1])


def main():
    rows = []
    for name, a, z, p in grng_fom.known_generators():
        if a is None:
            continue
        kind = "ROM uniform" if name.startswith("ROM") else "TreeGRNG"
        rows.append(dict(grng_fom.fom(z, p, name, a), kind=kind))
    for K, B, tag in ((8, 4, "gauss_lut_seg_K8_B4_l1"), (12, 4, "gauss_lut_seg_K12_B4_l1")):
        z, p = SegLut(SegLutConfig(K, B)).distribution()
        rows.append(dict(grng_fom.fom(z, p, f"segmented K={K} B={B}", area(tag)), kind="ROM segmented (ours)"))
    z, p = PwlLut(PwlConfig(12, 12)).distribution()
    rows.append(dict(grng_fom.fom(z, p, "PWL dyadic K=12 F=12 (Giles form)", area("gauss_lut_pwl_K12_F12_l1")), kind="PWL dyadic (Giles & S-M form)"))
    z, p = clt_grng.distribution()
    rows.append(dict(grng_fom.fom(z, p, "CLT-12", area("clt12_5ns")), kind="CLT-12"))

    out = ROOT / "results" / "grng_pareto.csv"
    with out.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)

    style = {"ROM uniform": ("o", "#4c72b0"), "TreeGRNG": ("^", "#dd8452"),
             "ROM segmented (ours)": ("*", "#c44e52"), "CLT-12": ("s", "#55a868"), "PWL dyadic (Giles & S-M form)": ("D", "#8172b2")}
    fig, (a1, a2) = plt.subplots(1, 2, figsize=(11.5, 4.4))
    for kind, (mk, col) in style.items():
        pts = [r for r in rows if r["kind"] == kind]
        if not pts:
            continue
        x = [r["area_um2"] / 1e3 for r in pts]
        a1.scatter(x, [r["call_worst_bias_pct"] for r in pts], marker=mk, s=140 if "ours" in kind else 70,
                   color=col, label=kind, zorder=3)
        for r, xi in zip(pts, x):
            lab = r["generator"].replace("ROM LUT ", "").replace("TreeGRNG ", "tree ").replace("segmented ", "seg ").replace(" (Giles form)", "")
            a1.annotate(f"{lab}\nKS {r['ks']:.4f}", (xi, r["call_worst_bias_pct"]), textcoords="offset points",
                        xytext=(7, -2), fontsize=6.8, color="#333")
        y2 = [abs(r["digital_K200_bias_pct"]) if r["digital_K200_hw"] > 0 else np.nan for r in pts]
        a2.scatter(x, y2, marker=mk, s=140 if "ours" in kind else 70, color=col, label=kind, zorder=3)
        for r, xi, yi in zip(pts, x, y2):
            if np.isnan(yi):
                a2.scatter([xi], [150], marker="x", s=80, color="#4c72b0", zorder=3)
                a2.annotate(r["generator"].replace("ROM LUT ", "") + ": returns 0 (-100 %)", (xi, 150), textcoords="offset points",
                            xytext=(6, -3), fontsize=6.8, color="#4c72b0")
    a1.axhline(1.0, color="#999", lw=0.8, ls=":"); a1.text(9.2, 1.08, "1 % target", fontsize=7.5, color="#666", ha="right")
    a1.set_yscale("log"); a1.set_xlabel("synthesised area [10^3 um^2], gscl45nm, 5 ns"); a1.set_ylabel("worst-case European-call bias [%]")
    a1.set_title("Pricing bias vs area: K-S does not predict the ranking", fontsize=10); a1.grid(alpha=.3, which="both"); a1.legend(fontsize=7.5, loc="upper right")
    a2.set_yscale("log"); a2.set_ylim(0.1, 400); a2.set_xlabel("synthesised area [10^3 um^2]")
    a2.set_ylabel("|bias| of digital call K=200 [%]  (tail probability 4e-4)")
    a2.set_title("Tail workload: uniform ROM has no tail at all", fontsize=10); a2.grid(alpha=.3, which="both")
    fig.tight_layout(); fig.savefig(ROOT / "docs" / "figures" / "grng_pareto.png", dpi=200, bbox_inches="tight")
    for r in rows:
        print(f"{r['generator']:<22}{r['area_um2']:>8.0f} um2  KS {r['ks']:.4f}  call {r['call_worst_bias_pct']:.3f}%  dig200 {r['digital_K200_bias_pct']:+.1f}%")
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
