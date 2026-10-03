"""Generate documentation figures into docs/figures/.  Run: make figures"""
from __future__ import annotations

from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

OUT = Path(__file__).resolve().parents[1] / "docs" / "figures"
MONO = {"family": "monospace", "size": 9}


def box(ax, x, y, w, h, label, sub=None, fc="#f4f6fa"):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.02,rounding_size=0.08",
                                fc=fc, ec="#333", lw=1.2))
    ax.text(x + w / 2, y + h / 2 + (0.12 if sub else 0), label, ha="center", va="center", **MONO)
    if sub:
        ax.text(x + w / 2, y + h / 2 - 0.16, sub, ha="center", va="center", size=7.5, color="#555")


def arrow(ax, p0, p1, label=None, sub=None, dy=0.1):
    ax.add_patch(FancyArrowPatch(p0, p1, arrowstyle="-|>", mutation_scale=12, lw=1.1, color="#222",
                                 shrinkA=0, shrinkB=0))
    if label:
        mx, my = (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2
        ax.text(mx, my + dy, label, ha="center", va="bottom", **MONO)
        if sub:
            ax.text(mx, my - dy, sub, ha="center", va="top", size=7.5, color="#555", family="monospace")


def lane_block_diagram(path: Path):
    fig, ax = plt.subplots(figsize=(10.5, 3.8))
    ax.set_xlim(0, 11.6)
    ax.set_ylim(0, 3.7)
    ax.axis("off")

    # mc_top frame
    ax.add_patch(FancyBboxPatch((1.0, 0.25), 8.9, 3.2, boxstyle="round,pad=0.02,rounding_size=0.1",
                                fc="none", ec="#888", lw=1.0, ls="--"))
    ax.text(1.15, 3.3, "mc_top  (Tyler)", ha="left", va="center", size=8.5, color="#555", family="monospace")

    # blocks
    box(ax, 1.3, 2.1, 1.7, 0.8, "controller", "FSM + counters")
    box(ax, 1.3, 0.55, 1.4, 0.8, "rng_lane", "xoshiro128++\n(Shentong)")
    box(ax, 3.8, 0.55, 1.4, 0.8, "gauss_lut", "inv-normal ROM\n(Chuanqi)")
    box(ax, 6.3, 0.55, 1.5, 0.8, "price_dp", "A+Bz, exp, payoff\n(Eric)")
    box(ax, 8.1, 1.75, 1.6, 0.9, "accumulator", "sum p, trial count\n(Eric)")

    # data flow
    arrow(ax, (2.7, 0.95), (3.8, 0.95), "u", "u_valid")
    arrow(ax, (5.2, 0.95), (6.3, 0.95), "z", "z_valid")
    arrow(ax, (7.8, 0.95), (8.9, 0.95), "p", "p_valid")
    ax.add_patch(FancyArrowPatch((8.9, 0.95), (8.9, 1.75), arrowstyle="-|>", mutation_scale=12, lw=1.1,
                                 color="#222", shrinkA=0, shrinkB=0))

    # control
    ax.add_patch(FancyArrowPatch((2.0, 2.1), (2.0, 1.35), arrowstyle="-|>", mutation_scale=12, lw=1.1,
                                 color="#222", shrinkA=0, shrinkB=0))
    ax.text(2.1, 1.72, "run, seed_load,\nseed_state", ha="left", va="center", size=7.5, family="monospace")
    arrow(ax, (3.0, 2.55), (8.1, 2.55), "clear", dy=0.06)
    ax.add_patch(FancyArrowPatch((8.1, 2.2), (3.0, 2.2), arrowstyle="-|>", mutation_scale=12, lw=1.1,
                                 color="#222", shrinkA=0, shrinkB=0))
    ax.text(5.5, 2.12, "trial_count", ha="center", va="top", size=8, family="monospace")

    # top-level I/O
    arrow(ax, (0.05, 2.75), (1.3, 2.75), "cfg bus", dy=0.06)
    arrow(ax, (0.05, 2.3), (1.3, 2.3), "start", dy=0.06)
    arrow(ax, (9.7, 2.2), (11.5, 2.2))
    ax.text(10.75, 2.1, "payoff_sum, trial_count,\ncycle_count, status", ha="center", va="top", size=7,
            family="monospace")
    arrow(ax, (3.0, 2.95), (11.5, 2.95))
    ax.text(10.6, 3.02, "busy, done", ha="center", va="bottom", size=8, family="monospace")

    fig.savefig(path, dpi=200, bbox_inches="tight")
    plt.close(fig)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    lane_block_diagram(OUT / "lane_block_diagram.png")
    print(f"wrote figures to {OUT}")


if __name__ == "__main__":
    main()
