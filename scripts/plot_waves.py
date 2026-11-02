"""Render documentation waveforms from the VCDs written by scripts/sim/dump_waves.sh.

A small VCD reader (no external dependency) plus a timing-diagram plotter, so the
figures in docs/figures/wave_*.png are reproducible from reports/waves/*.vcd
instead of being simulator screenshots.

    python3 scripts/plot_waves.py            # all three figures
    python3 scripts/plot_waves.py --list reports/waves/price_dp.vcd   # signal names
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
WAVES = ROOT / "reports" / "waves"
FIGS = ROOT / "docs" / "figures"


# ---- minimal VCD reader ------------------------------------------------------------
class Vcd:
    def __init__(self, path: Path):
        self.names: dict[str, list[str]] = {}     # id -> hierarchical names
        self.width: dict[str, int] = {}
        self.changes: dict[str, list[tuple[int, str]]] = {}
        self.timescale = "1ps"
        self._parse(path)

    def _parse(self, path: Path):
        scope: list[str] = []
        t = 0
        with path.open() as f:
            header = True
            for line in f:
                line = line.strip()
                if not line:
                    continue
                if header:
                    if line.startswith("$scope"):
                        scope.append(line.split()[2])
                    elif line.startswith("$upscope"):
                        scope.pop()
                    elif line.startswith("$var"):
                        p = line.split()
                        vid, name = p[3], p[4]
                        self.names.setdefault(vid, []).append(".".join(scope + [name]))
                        self.width[vid] = int(p[2])
                        self.changes.setdefault(vid, [])
                    elif line.startswith("$timescale"):
                        m = re.search(r"(\d+\s*[munpf]?s)", line)
                        if m:
                            self.timescale = m.group(1).replace(" ", "")
                    elif line.startswith("$enddefinitions"):
                        header = False
                    continue
                if line[0] == "#":
                    t = int(line[1:])
                elif line[0] in "01xXzZ":
                    self.changes[line[1:]].append((t, line[0]))
                elif line[0] in "bB":
                    val, vid = line[1:].split()
                    self.changes[vid].append((t, val))

    def find(self, pattern: str) -> str:
        """id of the unique signal whose hierarchical name ends with `pattern`."""
        hits = [(vid, n) for vid, ns in self.names.items() for n in ns if n.endswith(pattern)]
        if not hits:
            raise KeyError(pattern)
        # prefer the shortest (least nested) match
        return sorted(hits, key=lambda h: h[1].count("."))[0][0]

    def value_at(self, vid: str, t: int) -> str:
        v = "x"
        for tt, val in self.changes[vid]:
            if tt > t:
                break
            v = val
        return v

    def posedges(self, vid: str) -> list[int]:
        return [t for t, v in self.changes[vid] if v == "1"]


def fmt_value(bits: str, width: int, mode: str) -> str:
    if "x" in bits.lower() or "z" in bits.lower():
        return "x"
    n = int(bits, 2)
    if mode == "hex":
        return f"{n:0{(width + 3) // 4}x}"
    if mode == "sdec":
        if n >= 1 << (width - 1):
            n -= 1 << width
        return f"{n}"
    if mode.startswith("q"):          # q<frac>: fixed point real
        frac = int(mode[1:])
        if n >= 1 << (width - 1):
            n -= 1 << width
        return f"{n / (1 << frac):.3f}"
    if mode.startswith("uq"):
        frac = int(mode[2:])
        return f"{n / (1 << frac):.2f}"
    return f"{n}"


# ---- plotter -------------------------------------------------------------------------
def draw(vcd: Vcd, signals: list[tuple[str, str, str]], clk: str, cycles: range, title: str,
         path: Path, note: str | None = None):
    """signals: (label, name_suffix, mode) with mode in {bit, hex, sdec, q12, uq8, dec}."""
    edges = vcd.posedges(vcd.find(clk))
    sel = [edges[i] for i in cycles if i < len(edges)]
    period = edges[1] - edges[0]
    t0, t1 = sel[0] - period // 2, sel[-1] + period // 2
    n = len(signals)
    fig, ax = plt.subplots(figsize=(0.62 * len(sel) + 1.8, 0.48 * n + 0.9))
    ax.set_xlim(t0, t1)
    ax.set_ylim(-0.4, n - 0.2)
    ax.set_yticks([n - 1 - i for i in range(n)])
    ax.set_yticklabels([s[0] for s in signals], family="monospace", fontsize=8.5)
    ax.set_xticks(sel)
    ax.set_xticklabels([str(c) for c in cycles][: len(sel)], fontsize=7.5)
    ax.set_xlabel("clock cycle", fontsize=8)
    for s in ("top", "right"):
        ax.spines[s].set_visible(False)
    for e in sel:
        ax.axvline(e, color="#ddd", lw=0.6, zorder=0)

    for row, (label, name, mode) in enumerate(signals):
        y = n - 1 - row
        vid = vcd.find(name)
        w = vcd.width[vid]
        # sample value at each clock edge minus epsilon (what the flop sees) and
        # just after (what it outputs): plotting the value stable over [edge, next)
        pts = [(e, vcd.value_at(vid, e + 1)) for e in sel]
        if mode == "bit":
            xs, ys = [], []
            for i, (e, v) in enumerate(pts):
                hi = 0.0 if v == "0" else (0.7 if v == "1" else 0.35)
                xs += [e, e + period]
                ys += [hi, hi]
            color = "#2a6fdb" if label.endswith("valid") or label in ("run", "start", "done") else "#333"
            ax.step(xs, [y - 0.3 + v for v in ys], where="post", color=color, lw=1.4)
            for e, v in pts:
                if v not in "01":
                    ax.fill_between([e, e + period], y - 0.3, y + 0.4, color="#f4b6b6", alpha=0.6)
        else:
            prev = None
            start = sel[0]
            for i, (e, v) in enumerate(pts + [(sel[-1] + period, None)]):
                if v != prev or v is None:
                    if prev is not None:
                        x0, x1 = start, e
                        txt = fmt_value(prev, w, mode)
                        bad = txt == "x"
                        ax.add_patch(plt.Rectangle((x0 + period * 0.04, y - 0.3), x1 - x0 - period * 0.08, 0.6,
                                                   fc="#f4b6b6" if bad else "#eef2f8", ec="#555", lw=0.8))
                        if x1 - x0 >= period:
                            ax.text((x0 + x1) / 2, y, txt, ha="center", va="center", fontsize=7.2, family="monospace")
                    start, prev = e, v
    ax.set_title(title, fontsize=9.5, loc="left")
    if note:
        ax.text(0.0, -0.33, note, transform=ax.transAxes, fontsize=7.5, color="#444", va="top")
    fig.tight_layout()
    fig.savefig(path, dpi=200, bbox_inches="tight")
    plt.close(fig)
    print(f"wrote {path}")


def first_cycle_where(vcd: Vcd, name: str, value: str, clk: str) -> int:
    vid, edges = vcd.find(name), vcd.posedges(vcd.find(clk))
    for i, e in enumerate(edges):
        if vcd.value_at(vid, e + 1) == value:
            return i
    raise ValueError(f"{name} never {value}")


def fig_gauss(vcd: Vcd, out: Path):
    c0 = first_cycle_where(vcd, "dut.in_valid", "1", "dut.clk") - 2
    draw(vcd, [
        ("rst_n", "dut.rst_n", "bit"),
        ("in_valid", "dut.in_valid", "bit"),
        ("u[31:0]", "dut.u", "hex"),
        ("addr[9:0]", "dut.addr", "hex"),
        ("out_valid", "dut.out_valid", "bit"),
        ("z (Q3.12)", "dut.z", "q12"),
    ], "dut.clk", range(c0, c0 + 12), "gauss_lut, LATENCY = 1: one u in, one z out per cycle (II = 1); "
       "out_valid is in_valid delayed by one cycle", out,
       note="Vectors from tb/vectors/gauss_lut_a10_w16_f12.hex; first five are the corner words 0, 0xFFFFFFFF, 0x7FFFFFFF, 0x80000000, 1.\n"
            "z is a datapath register and is not reset (spec Sec. 2): x until the first valid beat, always qualified by out_valid.")


def fig_rng(vcd: Vcd, out: Path):
    c0 = first_cycle_where(vcd, "dut.seed_load", "1", "dut.clk") - 1
    draw(vcd, [
        ("rst_n", "dut.rst_n", "bit"),
        ("seed_load", "dut.seed_load", "bit"),
        ("run", "dut.run", "bit"),
        ("s0 (state)", "dut.s0", "hex"),
        ("u_valid", "dut.u_valid", "bit"),
        ("u[31:0]", "dut.u", "hex"),
    ], "dut.clk", range(c0, c0 + 12), "rng_lane (xoshiro128++): seed_load copies the state; "
       "reset or a zero state suppresses output; each run cycle then emits one word (LAT_RNG = 1)", out,
       note="From tb/tb_rng_lane.sv directed sequence; state word s0 shown, u is the ++ output of the previous state.")


def fig_price(vcd: Vcd, out: Path):
    c0 = first_cycle_where(vcd, "dut.z_valid", "1", "dut.clk") - 1
    draw(vcd, [
        ("z_valid", "dut.z_valid", "bit"),
        ("z (Q3.12)", "dut.z", "q12"),
        ("S1 v1", "dut.v1", "bit"),
        ("S2 v2 / x (Q5.12)", "dut.x2", "q12"),
        ("S3 v3", "dut.u_exp.v3", "bit"),
        ("S4 v4", "dut.u_exp.v4", "bit"),
        ("S5 v5 / S_T (UQ14.8)", "dut.st5", "uq8"),
        ("p_valid", "dut.p_valid", "bit"),
        ("p (UQ14.8)", "dut.p", "uq8"),
    ], "dut.clk", range(c0, c0 + 16), "price_dp, MUL_STAGES = 1: six-stage pipeline fills in LAT_DP = 6 cycles, "
       "then one payoff per cycle (II = 1) for every consecutive z_valid", out,
       note="A, B, K from the directed ATM case in tb/vectors/price_dp_k10.hex; stage valids v1..v5 travel beside the data.")


FIGURES = {
    "gauss_lut": fig_gauss,
    "rng_lane": fig_rng,
    "price_dp": fig_price,
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", type=Path, help="print signal names in a VCD and exit")
    ap.add_argument("--only", choices=list(FIGURES), nargs="*")
    a = ap.parse_args()
    if a.list:
        v = Vcd(a.list)
        for vid, ns in sorted(v.names.items(), key=lambda kv: kv[1][0]):
            print(f"{v.width[vid]:>3}  {ns[0]}")
        return
    FIGS.mkdir(parents=True, exist_ok=True)
    for name in (a.only or FIGURES):
        FIGURES[name](Vcd(WAVES / f"{name}.vcd"), FIGS / f"wave_{name}.png")


if __name__ == "__main__":
    main()
