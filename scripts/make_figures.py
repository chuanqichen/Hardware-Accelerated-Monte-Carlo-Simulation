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


# ---------------------------------------------------------------------------
# Gaussian LUT figures (use the bit-accurate model in model/)
# ---------------------------------------------------------------------------
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "model"))
import numpy as np                                   # noqa: E402
import gauss_lut as g                                # noqa: E402


def gauss_inverse_cdf(path: Path, addr_bits: int = 5):
    """Phi^-1(u) with the ROM staircase overlaid (small table so steps are visible)."""
    lut = g.GaussLut(g.GaussLutConfig(addr_bits, 16, 12))
    k = 16
    u = (np.arange(1 << k) + 0.5) / (1 << k)
    z_hw = lut.lookup_real((np.arange(1 << k, dtype=np.uint64) << np.uint64(32 - k)))
    z_true = g._inv_cdf(u)
    zmax = np.abs(z_hw).max()

    fig, ax = plt.subplots(figsize=(7.5, 4.2))
    ax.plot(u, z_true, color="#1f77b4", lw=1.6, label=r"exact $\Phi^{-1}(u)$")
    ax.step(u, z_hw, where="mid", color="#d62728", lw=1.2, label=f"ROM output, ADDR_BITS = {addr_bits} ({1 << addr_bits} cells)")
    n = 1 << addr_bits
    mids = (np.arange(n) + 0.5) / n
    ax.plot(mids, g._inv_cdf(mids), "o", ms=3, color="#d62728", label="table entries at cell midpoints")
    for s in (+1, -1):
        ax.axhline(s * zmax, color="#888", ls="--", lw=0.8)
    ax.annotate(rf"tail truncated at $|z| \leq {zmax:.2f}$", xy=(0.985, zmax), xytext=(0.62, 3.6),
                arrowprops=dict(arrowstyle="->", color="#555"), fontsize=9, color="#333")
    ax.axvline(0.5, color="#aaa", lw=0.6)
    ax.text(0.505, -4.4, "sign = addr MSB\n(symmetric half-table)", fontsize=8, color="#555")
    ax.set_xlim(0, 1); ax.set_ylim(-4.6, 4.6)
    ax.set_xlabel(r"uniform $u = \mathtt{u[31{:}0]}\,/\,2^{32}$"); ax.set_ylabel(r"$z$")
    ax.grid(alpha=0.3); ax.legend(loc="upper left", fontsize=8.5, framealpha=0.95)
    fig.savefig(path, dpi=200, bbox_inches="tight"); plt.close(fig)


def gauss_lut_datapath(path: Path):
    """Bit-level datapath of gauss_lut for ADDR_BITS=10, OUT_WIDTH=16 (compact, large fonts)."""
    fig, ax = plt.subplots(figsize=(11, 4.2))
    ax.set_xlim(0, 12.0); ax.set_ylim(-0.4, 3.9); ax.axis("off")
    Y = 1.9
    F = dict(family="monospace", size=10.5)
    FS = dict(family="monospace", size=9, color="#444")

    def blk(x, w, label, sub, fc):
        ax.add_patch(FancyBboxPatch((x, Y - 0.45), w, 0.9, boxstyle="round,pad=0.02,rounding_size=0.08",
                                    fc=fc, ec="#333", lw=1.2))
        ax.text(x + w / 2, Y, label, ha="center", va="center", **F)
        ax.text(x + w / 2, Y - 0.6, sub, ha="center", va="top", **FS)

    def wire(x0, x1, label=""):
        arrow(ax, (x0, Y), (x1, Y))
        if label:
            ax.text((x0 + x1) / 2, Y + 0.1, label, ha="center", va="bottom", family="monospace", size=9.5)

    segs = [(0.15, 0.4, "#f8b4b4", "s", "u[31]"), (0.55, 1.3, "#ffe08a", "j'[8:0]", "u[30:22]"),
            (1.85, 0.9, "#f3f3f3", "...", "u[21:0]")]
    for x, w, c, lab, bits in segs:
        ax.add_patch(FancyBboxPatch((x, Y - 0.32), w, 0.64, boxstyle="square,pad=0", fc=c, ec="#333"))
        ax.text(x + w / 2, Y, lab, ha="center", va="center", **F)
        ax.text(x + w / 2, Y - 0.42, bits, ha="center", va="top", **FS)
    ax.text(0.6, Y + 0.42, "u[31:0]   addr = u[31:22]", ha="left", va="bottom", **F)

    ax.plot([0.35, 0.35, 9.45], [Y + 0.32, 3.4, 3.4], color="#c0392b", lw=1.3)
    ax.text(4.9, 3.46, "sign = addr[9]  (1: upper half of (0,1), z >= 0)", ha="center", va="bottom",
            family="monospace", size=10, color="#c0392b")

    wire(2.75, 3.45, "j'")
    blk(3.45, 1.0, "XOR", "j = sign ?\n j' : ~j'", "#eef")
    ax.plot([3.95, 3.95], [3.4, Y + 0.45], color="#c0392b", lw=1.3)

    wire(4.45, 5.35, "j[8:0]")
    blk(5.35, 2.5, "ROM 512 x 16", "mag[j] = Q3.12($\\Phi^{-1}(p_j)$)\n$p_j = (512 + j + 0.5)/1024$", "#e8f5e9")

    wire(7.85, 8.85, "mag[15:0]")
    blk(8.85, 1.2, "negate", "sign ? +mag\n     : -mag", "#eef")
    ax.plot([9.45, 9.45], [3.4, Y + 0.45], color="#c0392b", lw=1.3)

    wire(10.05, 10.5)
    ax.add_patch(FancyBboxPatch((10.5, Y - 0.45), 0.55, 0.9, boxstyle="square,pad=0", fc="#ddd", ec="#333"))
    ax.text(10.775, Y, "D Q", ha="center", va="center", **F)
    ax.plot([10.65, 10.775, 10.9], [Y - 0.45, Y - 0.32, Y - 0.45], color="#333", lw=1)
    wire(11.05, 11.95, "z[15:0]")

    yv = 0.35
    arrow(ax, (0.15, yv), (10.5, yv)); ax.text(5.3, yv + 0.08, "in_valid", ha="center", va="bottom", **F)
    ax.add_patch(FancyBboxPatch((10.5, yv - 0.28), 0.55, 0.56, boxstyle="square,pad=0", fc="#ddd", ec="#333"))
    arrow(ax, (11.05, yv), (11.95, yv)); ax.text(11.1, yv + 0.1, "out_valid", ha="left", va="bottom", family="monospace", size=9.5)
    ax.text(6.0, -0.35, "LATENCY = 1 shown. LATENCY = 2 inserts a register between ROM and negate.",
            ha="center", va="bottom", size=9.5, color="#555")
    fig.savefig(path, dpi=200, bbox_inches="tight"); plt.close(fig)


def gauss_lut_error(path: Path):
    """(a) exact call-price bias vs ADDR_BITS; (b) hardware z distribution vs N(0,1) tails."""
    addr = [6, 8, 10, 12]
    fig, (a1, a2) = plt.subplots(1, 2, figsize=(10, 3.8))
    for label, *args in g.OPTION_GRID:
        ref = g.bs_call(*args)
        bias = [abs(100 * (g.GaussLut(g.GaussLutConfig(a, 16, 12)).exact_call_price(*args) - ref) / ref) for a in addr]
        a1.plot(addr, bias, "o-", label=label.replace("  ", " "))
    a1.set_yscale("log"); a1.set_xticks(addr)
    a1.set_xlabel("ADDR_BITS  (ROM = $2^{a-1}\\times 16$ bit)"); a1.set_ylabel("|price bias| from Gaussian block (%)")
    a1.set_title("(a) exact option-price bias vs table size", fontsize=10)
    a1.grid(alpha=0.3, which="both"); a1.legend(fontsize=7.5)
    sec = a1.secondary_xaxis("top", functions=(lambda a: a, lambda a: a))
    sec.set_xticks(addr); sec.set_xticklabels([f"{(1 << (a - 1)) * 16 / 1024:g} Kbit" for a in addr], fontsize=8)

    zz = np.linspace(-4.5, 4.5, 600)
    a2.plot(zz, np.exp(-zz**2 / 2) / np.sqrt(2 * np.pi), "k-", lw=1.4, label=r"$\mathcal{N}(0,1)$ density")
    for a, c in ((8, "#d62728"), (10, "#2ca02c")):
        z = g.GaussLut(g.GaussLutConfig(a, 16, 12)).all_outputs()
        a2.hist(z, bins=np.arange(-4.5, 4.51, 0.25), density=True, histtype="step", lw=1.3, color=c,
                label=f"hardware z, ADDR_BITS = {a} (|z| <= {np.abs(z).max():.2f})")
    a2.set_yscale("log"); a2.set_ylim(1e-5, 1); a2.set_xlabel("$z$"); a2.set_ylabel("density (log)")
    a2.set_title("(b) output distribution: body exact, tails truncated", fontsize=10)
    a2.grid(alpha=0.3, which="both"); a2.legend(fontsize=7.5, loc="lower center")
    fig.tight_layout(); fig.savefig(path, dpi=200, bbox_inches="tight"); plt.close(fig)


def qformat_layout(path: Path):
    """Bit layout of Q3.12 with worked examples (z = +1.5, +3.297, -3.297)."""
    fig, ax = plt.subplots(figsize=(10, 3.0))
    ax.set_xlim(-0.3, 21.5); ax.set_ylim(-1.6, 2.3); ax.axis("off")
    weights = ["-8", "4", "2", "1"] + [f"2^-{i}" for i in range(1, 13)]
    colors = ["#f8b4b4"] + ["#ffe08a"] * 3 + ["#cfe8ff"] * 12
    for i in range(16):
        ax.add_patch(FancyBboxPatch((i, 0.6), 1, 0.8, boxstyle="square,pad=0", fc=colors[i], ec="#333"))
        ax.text(i + 0.5, 1.0, weights[i], ha="center", va="center", size=8.5 if i < 13 else 7, family="monospace")
        ax.text(i + 0.5, 1.58, str(15 - i), ha="center", va="center", size=8.5, color="#555")
    ax.text(0.5, 2.0, "sign", ha="center", size=10); ax.text(2.5, 2.0, "integer (3)", ha="center", size=10)
    ax.text(10, 2.0, "fraction (12)   LSB = 2^-12 = 0.000244", ha="center", size=10)
    ax.text(16.3, 1.0, "bit weight", ha="left", va="center", size=9, color="#555")

    def row(y, bits, label):
        for i, b in enumerate(bits):
            ax.text(i + 0.5, y, b, ha="center", va="center", family="monospace", size=11)
        ax.text(16.3, y, label, ha="left", va="center", family="monospace", size=10)

    row(0.1, format(0x1800, "016b"), "z = +1.5    raw 0x1800")
    row(-0.5, format(0x34C1, "016b"), "z = +3.297  raw 0x34C1")
    row(-1.1, format(0xCB3F, "016b"), "z = -3.297  raw 0xCB3F")
    fig.savefig(path, dpi=200, bbox_inches="tight"); plt.close(fig)


def gauss_lut_timing(path: Path):
    """Waveform: valid-only streaming with LATENCY = 1."""
    fig, ax = plt.subplots(figsize=(9, 3.0))
    ax.set_xlim(0, 9); ax.set_ylim(-0.7, 4.9); ax.axis("off")
    t = np.arange(0, 9.01, 0.01)

    def sig(y, v, color, name):
        ax.plot(t, y + 0.6 * v, color, lw=1.3); ax.text(-0.1, y + 0.3, name, ha="right", va="center", **MONO)

    def bus(y, cells, color, name):
        for (x0, x1, lab) in cells:
            ax.add_patch(FancyBboxPatch((x0 + 0.03, y), x1 - x0 - 0.06, 0.6, boxstyle="square,pad=0", fc=color, ec="#333"))
            ax.text((x0 + x1) / 2, y + 0.3, lab, ha="center", va="center", size=8, family="monospace")
        ax.text(-0.1, y + 0.3, name, ha="right", va="center", **MONO)

    sig(4.0, ((t * 2) % 2 < 1).astype(float), "k", "clk")
    vin = np.where((t >= 1) & (t < 5), 1.0, 0.0) + np.where((t >= 6) & (t < 7), 1.0, 0.0)
    sig(2.9, vin, "#1f77b4", "in_valid")
    bus(2.0, [(1, 2, "u0"), (2, 3, "u1"), (3, 4, "u2"), (4, 5, "u3"), (6, 7, "u4")], "#ffe08a", "u")
    vout = np.where((t >= 2) & (t < 6), 1.0, 0.0) + np.where((t >= 7) & (t < 8), 1.0, 0.0)
    sig(0.8, vout, "#2ca02c", "out_valid")
    bus(-0.1, [(2, 3, "z0"), (3, 4, "z1"), (4, 5, "z2"), (5, 6, "z3"), (7, 8, "z4")], "#cfe8ff", "z")

    ax.annotate("", xy=(2, 1.75), xytext=(1, 1.75), arrowprops=dict(arrowstyle="<->", color="#c0392b"))
    ax.text(1.5, 1.68, "LATENCY = 1", ha="center", va="top", size=8, color="#c0392b")
    ax.text(6.5, 0.2, "bubble\npropagates", ha="center", va="center", size=7.5, color="#555")
    ax.text(4.5, -0.55, "one z per cycle while in_valid is high; no back-pressure", ha="center", va="top", size=8, color="#555")
    fig.savefig(path, dpi=200, bbox_inches="tight"); plt.close(fig)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    lane_block_diagram(OUT / "lane_block_diagram.png")
    gauss_inverse_cdf(OUT / "gauss_inverse_cdf.png")
    gauss_lut_datapath(OUT / "gauss_lut_datapath.png")
    gauss_lut_error(OUT / "gauss_lut_error.png")
    qformat_layout(OUT / "qformat_q3_12.png")
    gauss_lut_timing(OUT / "gauss_lut_timing.png")
    print(f"wrote figures to {OUT}")


if __name__ == "__main__":
    main()
