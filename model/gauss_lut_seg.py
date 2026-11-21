"""Tail-refined segmented inverse-CDF table (research, claim C3 / T3).

The uniform ROM (gauss_lut.py) spends its 2^(a-1) entries evenly in u, so the far tail
gets one cell and everything beyond |z|max = Phi^-1(1 - 2^-(a+1)) is lost. This table
spends entries evenly in *log2(t)*, t = tail probability:

  sign = u[31];  m = sign ? ~u[30:0] : u[30:0]  in [0, 2^31)       t = (m + 1/2) / 2^32
  k    = clz31(m)                                                  band: t in [2^-(k+2), 2^-(k+1))
  j    = the B bits of m just below the leading one                sub-cell within the band
  z    = (sign ? + : -) ROM[min(k, K-1)][j]

Band k < K-1 has 2^B cells of equal probability 2^-(k+2+B). The last band (k >= K-1) covers
the whole remaining tail t in (0, 2^-K) with 2^B cells indexed by the same bit positions,
so z reaches Phi^-1(1 - 2^-(K+B+1)) and no tail mass is dropped beyond it. ROM size is
K * 2^B entries of OUT_WIDTH bits, versus 2^(a-1) for the uniform table.

Entries are Phi^-1 at the cell's midpoint in t, quantised to Q3.12 (same output format
and rounding policy as gauss_lut). Everything is exact and enumerable, so grng_fom.fom()
applies directly.

    python3 model/gauss_lut_seg.py            # sweep (K, B) -> results/seg_lut_sweep.csv
"""
from __future__ import annotations

import csv
from dataclasses import dataclass
from pathlib import Path
from statistics import NormalDist

import numpy as np

from fxp import Fxp

ROOT = Path(__file__).resolve().parents[1]
N = NormalDist()


@dataclass(frozen=True)
class SegLutConfig:
    segments: int = 12        # K: number of dyadic bands (last one absorbs the far tail)
    sub_bits: int = 5         # B: bits per band -> 2^B cells per band
    out_width: int = 16
    frac_bits: int = 12

    @property
    def out_fmt(self) -> Fxp:
        return Fxp(self.out_width, self.frac_bits)

    @property
    def entries(self) -> int:
        return self.segments << self.sub_bits

    @property
    def rom_bits(self) -> int:
        return self.entries * self.out_width

    @property
    def name(self) -> str:
        return f"seg_K{self.segments}_B{self.sub_bits}_{self.out_fmt}"

    @property
    def equiv_addr_bits(self) -> float:
        """Uniform-ROM ADDR_BITS with the same entry count (for matched-size comparison)."""
        return 1 + np.log2(self.entries)


class SegLut:
    def __init__(self, cfg: SegLutConfig):
        self.cfg = cfg
        self.fmt = cfg.out_fmt
        K, B = cfg.segments, cfg.sub_bits
        rom = np.zeros((K, 1 << B))
        prob = np.zeros((K, 1 << B))
        for k in range(K):
            lo, hi = (2.0 ** -(k + 2), 2.0 ** -(k + 1)) if k < K - 1 else (0.0, 2.0 ** -(k + 1))
            width = (hi - lo) / (1 << B)
            for j in range(1 << B):
                t_mid = lo + (j + 0.5) * width
                rom[k, j] = N.inv_cdf(1.0 - t_mid)
                prob[k, j] = width                      # per sign
        self.rom = self.fmt.quantize(rom, saturate=False)
        self.prob_half = prob                           # sums to 1/2 per sign
        assert abs(prob.sum() - 0.5) < 1e-12

    # ---- bit-accurate lookup (what the RTL does) --------------------------------------
    def lookup(self, u):
        u = np.asarray(u, dtype=np.uint64)
        K, B = self.cfg.segments, self.cfg.sub_bits
        sign = (u >> np.uint64(31)) & np.uint64(1)
        m = np.where(sign == 1, (~u) & np.uint64(0x7FFFFFFF), u & np.uint64(0x7FFFFFFF)).astype(np.int64)
        # clz over 31 bits: position of the leading one
        msb = np.where(m > 0, np.floor(np.log2(np.maximum(m, 1))).astype(np.int64), -1)
        k = np.clip(30 - msb, 0, K - 1)
        # j = B bits below the leading one of band k (for the last band, the same positions)
        shift = 30 - k - B
        j = np.where(shift >= 0, (m >> np.maximum(shift, 0)) & ((1 << B) - 1),
                     (m << np.maximum(-shift, 0)) & ((1 << B) - 1))
        mag = self.rom[k, j]
        z = np.where(sign == 1, mag, -mag)
        self.fmt.check(z)
        return z

    # ---- exact output distribution ------------------------------------------------------
    def distribution(self):
        """(z_real, p) over all cells and both signs; exact."""
        mag = self.fmt.to_real(self.rom).ravel()
        p = self.prob_half.ravel()
        return np.concatenate([mag, -mag]), np.concatenate([p, p])

    def max_abs_z(self) -> float:
        return float(self.fmt.to_real(self.rom).max())


def sweep(ks=(8, 10, 12, 14, 16, 20), bs=(3, 4, 5, 6)):
    import grng_fom
    from gauss_lut import GaussLut, GaussLutConfig
    rows = []
    for a in (8, 10, 12):
        lut = GaussLut(GaussLutConfig(a, 16, 12)); z = np.asarray(lut.all_outputs())
        r = grng_fom.fom(z, np.full(len(z), 1 / len(z)), f"uniform a={a}")
        r.update(kind="uniform", entries=1 << (a - 1), rom_bits=(1 << (a - 1)) * 16, max_abs_z=float(np.abs(z).max()))
        rows.append(r)
    for K in ks:
        for B in bs:
            cfg = SegLutConfig(K, B); lut = SegLut(cfg)
            z, p = lut.distribution()
            r = grng_fom.fom(z, p, cfg.name)
            r.update(kind="segmented", K=K, B=B, entries=cfg.entries, rom_bits=cfg.rom_bits, max_abs_z=lut.max_abs_z())
            rows.append(r)
    return rows


def main():
    rows = sweep()
    out = ROOT / "results" / "seg_lut_sweep.csv"
    keys = sorted({k for r in rows for k in r}, key=lambda k: (k != "generator", k))
    with out.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=keys); w.writeheader(); w.writerows(rows)
    print(f"{'table':<22}{'entries':>8}{'max|z|':>7}{'KS':>8}{'P>3.5 err%':>11}{'call worst':>11}{'dig K180':>9}{'dig K200':>9}")
    for r in rows:
        print(f"{r['generator']:<22}{r['entries']:>8}{r['max_abs_z']:>7.2f}{r['ks']:>8.4f}{r['tail_3.5_rel_err_pct']:>+11.1f}"
              f"{r['call_worst_bias_pct']:>10.3f}%{r['digital_K180_bias_pct']:>+8.1f}%{r['digital_K200_bias_pct']:>+8.1f}%")
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
