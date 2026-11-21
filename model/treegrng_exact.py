"""Exact (product-form) output distribution of the TreeGRNG 8-bit example (R3).

Uses the comparator thresholds parsed from topgrng8_8.sv and the mux selection map probed
from the real decision tree with tb/tb_tree_probe.sv (results/treegrng8_tree_map.txt). The
comparator probability uses the XNOR-LFSR statistics (all-ones state never occurs):
P(x >= T) = (2^L - 1 - T) / (2^L - 1). Product form assumes the eight LFSR words are
independent at each cycle; the measured 4M-cycle histogram shows a small residual
(sum|diff| ~ 0.03) because the LFSR periods share factors (255 and 1023 are both
divisible by 3), so the real design's levels are weakly dependent - a point the paper
makes: the FoM must be applied to the RTL, not the design intent.

    python3 model/treegrng_exact.py -> results/treegrng8_exact_dist.csv
"""
import re
from pathlib import Path
import numpy as np
import grng_fom as g

ROOT = Path(__file__).resolve().parents[1]
TREE_PORT_WIDTH = {6: 1, 5: 2, 4: 4, 3: 8, 2: 16, 1: 16, 0: 8}


def exact_distribution():
    sv = (ROOT / "rtl/third_party/treegrng/topgrng8_8.sv").read_text()
    widths = {int(m.group(2)): 8 + (int(m.group(1)) if m.group(1) else 0)
              for m in re.finditer(r"LFSR\s*#\(\.NUM_BITS\(BITNUMS([+-]\d+)?\)\)\s*LFSR(\d)", sv)}
    P = {k: {} for k in range(8)}
    for m in re.finditer(r"propabmaker\s*#\(.*?\.T\(([\d.]+)\*.*?\)\s*prob\d+\s*\([^,]+,\s*pBit(\d)(?:\[(\d+)\])?\)", sv):
        frac, lvl, idx = float(m.group(1)), int(m.group(2)), int(m.group(3) or 0)
        L = widths[lvl]; T = int(frac * (1 << L))
        P[lvl][idx] = ((1 << L) - 1 - T) / ((1 << L) - 1)
    for m in re.finditer(r"assign\s+pBit(\d)\[(\d+)\]\s*=\s*pBit\d\[(\d+)\];", sv):
        P[int(m.group(1))][int(m.group(2))] = ("copy", int(m.group(3)))
    for m in re.finditer(r"assign\s+pBit(\d)\[(\d+)\]\s*=\s*!unfilteredLFSR\d\[0\];", sv):
        P[int(m.group(1))][int(m.group(2))] = 0.5
    for lvl in P:
        for j, v in list(P[lvl].items()):
            if isinstance(v, tuple):
                P[lvl][j] = P[lvl][v[1]]
    MAP = {}
    for line in (ROOT / "results/treegrng8_tree_map.txt").open():
        lvl, pre, idx, inv = map(int, line.split()[1:])
        MAP[(lvl, pre)] = (TREE_PORT_WIDTH[lvl] - 1 - idx, inv)   # [0:n-1] port vs [n-1:0] wire
    dist = {}
    for code in range(256):
        b = {k: (code >> k) & 1 for k in range(8)}; b[7] ^= 1
        p = 0.5; prefix = b[7]
        for lvl in range(6, -1, -1):
            idx, inv = MAP[(lvl, prefix)]; p1 = P[lvl][idx]
            if inv: p1 = 1 - p1
            p *= p1 if b[lvl] else 1 - p1
            prefix = (prefix << 1) | b[lvl]
        dist[code] = p
    codes = np.array(sorted(dist)); pe = np.array([dist[c] for c in codes])
    return codes, np.where(codes >= 128, codes - 256, codes) / 32, pe


if __name__ == "__main__":
    codes, z, pe = exact_distribution()
    h = {int(l.split()[1]): int(l.split()[2]) for l in (ROOT / "results/treegrng_sim_hist.txt").open()}; n = sum(h.values())
    ph = np.array([h.get(int(c), 0) / n for c in codes])
    print(f"max|exact-hist| {np.max(np.abs(pe-ph)):.2e}  sum|diff| {np.sum(np.abs(pe-ph)):.4f}")
    for nm, p in (("exact", pe), ("hist ", ph)):
        r = g.fom(z, p, nm, 2144)
        print(f"{nm}: var {r['var']:.4f} KS {r['ks']:.4f} call worst {r['call_worst_bias_pct']:.3f}% dig200 {r['digital_K200_bias_pct']:+.1f}%")
    np.savetxt(ROOT / "results/treegrng8_exact_dist.csv", np.c_[codes, z, pe], delimiter=",", header="code,z,p_exact", comments="", fmt=["%d", "%.6f", "%.10e"])
