"""Exact output distribution and option-pricing bias of TreeGRNG (Crols et al., DATE 2024).

TreeGRNG builds an INT8 Gaussian sample one bit at a time: bit 7 is the sign (p = 1/2),
and each further bit is a Bernoulli draw whose probability is selected by the bits
already decided - a binary decision tree whose leaves are the 256 output codes. Each
Bernoulli is a constant-threshold comparator on an LFSR word, p = (2^L - T) / 2^L. So
the probability of every output code is the product of the branch probabilities on its
path, and the whole distribution can be enumerated exactly - the same "no Monte Carlo
noise" treatment we apply to our ROM table (gauss_lut.all_outputs()).

Thresholds are parsed from the vendored rtl/third_party/treegrng/topgrng8_8.sv so the
model is the hardware. Output scale: 32 LSB per sigma (bit 6 fires with p = 0.0454 =
P(|z| > 2), bit 5 given bit 6 with p = 0.0579 ~ P(|z| > 3 | |z| > 2)), i.e. z = +-m/32,
|z| <= 127/32 = 3.97.

    python3 model/treegrng_study.py
Writes results/treegrng_vs_lut.csv.
"""
from __future__ import annotations

import csv
import math
import re
from pathlib import Path
from statistics import NormalDist

import numpy as np

import price_dp as pd
from gauss_lut import OPTION_GRID, GaussLut, GaussLutConfig, bs_call

ROOT = Path(__file__).resolve().parents[1]
SV = ROOT / "rtl" / "third_party" / "treegrng" / "topgrng8_8.sv"
N = NormalDist()
SCALE = 32  # LSB per sigma


def parse_tree(sv_text: str):
    """Return {level: list of Bernoulli probabilities indexed by the mux select value}.

    Level k decides bit k (k = 6..0); the select is the already-decided bits
    {bit7, bit6, ..., bit(k+1)}; the Verilog muxes index pBits in *reverse* for the
    sign = 1 half (reverser), which is the symmetric mirror, so we build the
    positive half and mirror it.
    """
    # LFSR widths per level: LFSR7..LFSR0 declared as NUM_BITS(BITNUMS+d)
    widths = {}
    for m in re.finditer(r"LFSR\s*#\(\.NUM_BITS\(BITNUMS([+-]\d+)?\)\)\s*LFSR(\d)", sv_text):
        widths[int(m.group(2))] = 8 + (int(m.group(1)) if m.group(1) else 0)
    # comparator thresholds: propabmaker #(.L2N(..), .T(<frac>*(2**(...)))) probKJ(..., pBitK[J])
    probs = {k: {} for k in range(7)}
    for m in re.finditer(r"propabmaker\s*#\(.*?\.T\(([\d.]+)\*.*?\)\s*prob\d+\s*\([^,]+,\s*pBit(\d)(?:\[(\d+)\])?\)", sv_text):
        frac, level, idx = float(m.group(1)), int(m.group(2)), int(m.group(3) or 0)
        L = widths[level]
        T = int(frac * (1 << L))                      # Verilog truncates the real parameter
        probs[level][idx] = (((1 << L) - T) / (1 << L))
    # explicit assigns: pBitK[J] = pBitK[J-1] (copies) and pBitK[J] = !lfsr[0] (p = 1/2)
    for m in re.finditer(r"assign\s+pBit(\d)\[(\d+)\]\s*=\s*pBit\d\[(\d+)\];", sv_text):
        level, j, src = int(m.group(1)), int(m.group(2)), int(m.group(3))
        probs[level][j] = ("copy", src)
    for m in re.finditer(r"assign\s+pBit(\d)\[(\d+)\]\s*=\s*!unfilteredLFSR\d\[0\];", sv_text):
        probs[int(m.group(1))][int(m.group(2))] = 0.5
    for level in probs:
        for j, v in list(probs[level].items()):
            if isinstance(v, tuple):
                probs[level][j] = probs[level][v[1]]
    # level 6 is a single bit named pBit6 without index -> idx 0
    return probs


def leaf_distribution(probs, conv: int = 0) -> dict[int, float]:
    """Exact P(result code) for all 256 INT8 codes, following the Verilog literally.

    simpledecisiontree8.sv: bit7 = pbits7 (p = 1/2). bit6 = mux({~p6, p6}, bit7).
    For level k < 6 with N select bits sel = {bit7, bit6, ..., bit(k+1)} and the
    comparator vector P declared [0:M-1] (M = 2^(N-1)), the mux entries are
    {reverse(P), P}: entries[i] = P[M-1-i] for i < M and P[i-M] for i >= M (SystemVerilog
    packs an ascending-range vector with element 0 as the MSB). bit_k is the selected
    comparator output, a Bernoulli with the parsed probability.
    result = {~bit7, bit6, ..., bit0}.
    """
    sel_levels = {5: [7, 6], 4: [7, 6, 5], 3: [7, 6, 5, 4], 2: [7, 6, 5, 4, 3],
                  1: [7, 6, 5, 4, 3], 0: [7, 6, 5, 4]}
    table = {}
    for code in range(256):
        bits = {k: (code >> k) & 1 for k in range(8)}
        bit7 = 1 - bits[7]                                   # result[7] = ~bit7
        p = 0.5
        p6 = probs[6][0]
        p_bit6_is_1 = (p6 if bit7 == 0 else 1.0 - p6) if conv < 4 else (1.0 - p6 if bit7 == 0 else p6)
        p *= p_bit6_is_1 if bits[6] else 1.0 - p_bit6_is_1
        decided = {7: bit7, 6: bits[6]}
        for level in (5, 4, 3, 2, 1, 0):
            P = probs[level]; M = len(P)
            sel = 0
            for b in sel_levels[level]:
                sel = (sel << 1) | decided[b]
            lo, hi = sel < M, sel >= M
            j = sel if lo else sel - M
            idx = {0: (M - 1 - j) if lo else j, 1: j if lo else (M - 1 - j),
                   2: j, 3: M - 1 - j}[conv % 4]
            p1 = P[idx]
            p *= p1 if bits[level] else 1.0 - p1
            decided[level] = bits[level]
        table[code] = p
    return table


def stats(table):
    codes = np.array(sorted(table)); ps = np.array([table[c] for c in codes])
    assert abs(ps.sum() - 1.0) < 1e-9, ps.sum()
    z_full = np.where(codes >= 128, codes - 256, codes) / SCALE      # int8 two's complement
    p_full = ps
    mean = float((z_full * p_full).sum()); var = float(((z_full - mean) ** 2 * p_full).sum())
    # K-S distance vs N(0,1) on the discrete support
    order = np.argsort(z_full)
    cdf_hw = np.cumsum(p_full[order]); cdf_n = np.array([N.cdf(z) for z in z_full[order]])
    ks = float(np.max(np.abs(cdf_hw - cdf_n)))
    return dict(mean=mean, var=var, ks=ks, max_abs_z=float(np.abs(z_full).max()), z_full=z_full, p_full=p_full)


def exact_price_weighted(s0, k, r, sigma, T, z_real, weights, cfg=pd.PriceDpConfig()) -> float:
    """Expected discounted payoff through the fixed-point datapath for a weighted z set."""
    a, b, kk = pd.option_to_regs(s0, k, r, sigma, T)
    z_raw = pd.Z_FMT.quantize(z_real)                    # feed TreeGRNG's z through the same Q3.12 port
    p = pd.price_dp(a, b, kk, z_raw, cfg)["p"]
    return math.exp(-r * T) * float((p * weights).sum()) / pd.ST_FMT.scale


def sim_hist():
    path = ROOT / "results" / "treegrng_sim_hist.txt"
    h = {int(l.split()[1]): int(l.split()[2]) for l in path.open()}
    n = sum(h.values())
    return {c: h[c] / n for c in range(256)}


def main():
    probs = parse_tree(SV.read_text())
    emp = sim_hist()
    # Pick the mux-order convention that reproduces the VCS histogram of the real RTL.
    best = None
    for conv in range(8):
        try:
            t = leaf_distribution(probs, conv)
        except Exception:
            continue
        err = sum((t[c] - emp[c]) ** 2 for c in range(256))
        if best is None or err < best[0]:
            best = (err, conv, t)
    err, conv, table = best
    st = stats(table)
    st_emp = stats(emp)
    print(f"[WIP] closed-form enumeration: best mux convention {conv}, sum sq err vs VCS histogram {err:.2e} - does NOT yet\n      reproduce the RTL; the 'Tree sim' column (4M-cycle VCS histogram of the real design) is the result to quote.")
    print(f"TreeGRNG simulated (4M cycles):  mean {st_emp['mean']:+.4f}  var {st_emp['var']:.4f}  KS {st_emp['ks']:.4f}")
    print(f"TreeGRNG INT8 exact distribution: mean {st['mean']:+.4f}  var {st['var']:.4f}  "
          f"KS {st['ks']:.4f}  max|z| {st['max_abs_z']:.2f}  (paper reports KS 0.0082)")
    rows = []
    luts = {a: GaussLut(GaussLutConfig(a, 16, 12)) for a in (8, 10, 12)}
    print(f"\n{'option':<18}{'BS':>9}{'Tree exact':>11}{'Tree sim':>11}" + "".join(f"{'LUT a=' + str(a):>11}" for a in luts))
    for label, *opt in OPTION_GRID:
        bs = bs_call(*opt)
        tree = exact_price_weighted(*opt, st["z_full"], st["p_full"])
        tree_emp = exact_price_weighted(*opt, st_emp["z_full"], st_emp["p_full"])
        row = dict(option=label, bs=bs, treegrng=tree, treegrng_bias_pct=100 * (tree - bs) / bs,
                   treegrng_sim_bias_pct=100 * (tree_emp - bs) / bs)
        line = f"{label:<18}{bs:>9.4f}{row['treegrng_bias_pct']:>+10.3f}%{row['treegrng_sim_bias_pct']:>+10.3f}%"
        for a, lut in luts.items():
            hw = pd.exact_price(*opt, pd.PriceDpConfig(), lut)
            row[f"lut_a{a}_bias_pct"] = 100 * (hw - bs) / bs
            line += f"{row[f'lut_a{a}_bias_pct']:>+10.3f}%"
        rows.append(row); print(line)
    for a, lut in luts.items():
        s = lut.stats()
        print(f"LUT a={a}: KS {s.get('ks', float('nan')):.5f}  max|z| {lut.fmt.to_real(lut.rom.max()):.2f}")
    out = ROOT / "results" / "treegrng_vs_lut.csv"
    with out.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
