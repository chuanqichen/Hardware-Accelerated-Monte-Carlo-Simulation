"""Bit-accurate model of the inverse-normal (quantile) lookup block.

Maps a 32-bit uniform word `u` to a fixed-point approximately-Gaussian `z`.

Mode "rom" (integration-first):
    addr = u[31 : 32-ADDR_BITS]              (top ADDR_BITS bits)
    p    = (addr + 0.5) / 2**ADDR_BITS       (cell midpoint, never 0 or 1)
    z    = Phi^-1(p) quantized to Fxp(OUT_WIDTH, FRAC_BITS)
  Symmetry Phi^-1(1-p) = -Phi^-1(p) lets hardware store only the upper half:
    sign = addr[ADDR_BITS-1];  j = addr[ADDR_BITS-2:0] if sign else ~addr[...]
    z    = +rom[j] if sign else -rom[j]

Mode "pwl" (planned upgrade for the numerical tradeoff study):
    Same ADDR_BITS segment select, then the next INTERP_BITS bits of `u` form a
    fraction f in [0,1) and z = knot[addr] + slope[addr] * f, where knots sit on
    cell edges p = addr / 2**ADDR_BITS (the two outer cells are clamped). The
    multiply is INTERP_BITS x SLOPE_BITS and the result is rounded once.

Everything here is exact over the finite input space, so the statistics below
are *exact properties of the hardware output distribution*, not Monte Carlo
estimates. Run as a script for a parameter sweep; import for use in the
full-pipeline reference model and in testbench vector generation.
"""
from __future__ import annotations

import argparse
import math
from dataclasses import dataclass
from pathlib import Path
from statistics import NormalDist

import numpy as np

from fxp import Fxp

_N = NormalDist()
EVAL_BITS = 20  # common evaluation grid for pointwise error metrics
_inv_cdf = np.vectorize(_N.inv_cdf, otypes=[np.float64])
_cdf = np.vectorize(_N.cdf, otypes=[np.float64])


@dataclass(frozen=True)
class GaussLutConfig:
    addr_bits: int = 8
    out_width: int = 16
    frac_bits: int = 12
    mode: str = "rom"          # "rom" | "pwl"
    interp_bits: int = 0       # pwl only
    slope_bits: int = 0        # pwl only; 0 -> same as out_width

    @property
    def out_fmt(self) -> Fxp:
        return Fxp(self.out_width, self.frac_bits)

    @property
    def used_bits(self) -> int:
        return self.addr_bits + (self.interp_bits if self.mode == "pwl" else 0)

    @property
    def name(self) -> str:
        if self.mode == "rom":
            return f"rom_a{self.addr_bits}_{self.out_fmt}"
        return f"pwl_a{self.addr_bits}_i{self.interp_bits}_{self.out_fmt}"

    def rom_bits(self) -> int:
        """Storage actually needed by hardware (half table thanks to symmetry)."""
        half = 1 << (self.addr_bits - 1)
        if self.mode == "rom":
            return half * self.out_width
        return half * (self.out_width + (self.slope_bits or self.out_width))


class GaussLut:
    def __init__(self, cfg: GaussLutConfig):
        self.cfg = cfg
        self.fmt = cfg.out_fmt
        n = 1 << cfg.addr_bits
        half = n >> 1
        if cfg.mode == "rom":
            # positive half: addr = half + j, j in [0, half)
            p = (half + np.arange(half) + 0.5) / n
            self.rom = self.fmt.quantize(_inv_cdf(p), saturate=False)
        elif cfg.mode == "pwl":
            if cfg.interp_bits < 1:
                raise ValueError("pwl mode needs interp_bits >= 1")
            # knots on cell edges for addr = half..n-1. Linear interpolation
            # across the outermost cell overshoots badly (Phi^-1 is strongly
            # convex there), so that segment falls back to the ROM midpoint
            # value with zero slope. Fixing this properly needs nonuniform
            # (tail-refined) segmentation — see the work plan.
            edges = (half + np.arange(half + 1)) / n
            knots = _inv_cdf(edges[:-1])
            slopes = np.diff(knots)
            knots[-1] = _N.inv_cdf(1.0 - 0.5 / n)
            slopes = np.append(slopes, 0.0)
            self.knot = self.fmt.quantize(knots, saturate=False)
            sfmt = Fxp(cfg.slope_bits or cfg.out_width, cfg.frac_bits, signed=False)
            self.slope_fmt = sfmt
            self.slope = sfmt.quantize(slopes, saturate=False)
        else:
            raise ValueError(cfg.mode)

    # ---- bit-accurate lookup ------------------------------------------------
    def lookup(self, u):
        """uint32 array -> raw signed fixed-point words (int64)."""
        u = np.asarray(u, dtype=np.uint64)
        a = self.cfg.addr_bits
        addr = (u >> np.uint64(32 - a)).astype(np.int64)
        half = 1 << (a - 1)
        sign = addr >= half                       # True -> positive z
        j = np.where(sign, addr - half, (half - 1) - addr)
        if self.cfg.mode == "rom":
            mag = self.rom[j]
        else:
            b = self.cfg.interp_bits
            f = ((u >> np.uint64(32 - a - b)) & np.uint64((1 << b) - 1)).astype(np.int64)
            # mirror the fraction for the negative half so z stays monotonic in u
            f = np.where(sign, f, (1 << b) - 1 - f)
            # knot + slope*f/2^b, rounded half-to-even once
            prod = self.slope[j] * f
            mag = self.knot[j] + _round_shift_even(prod, b)
        z = np.where(sign, mag, -mag)
        self.fmt.check(z)
        return z

    def lookup_real(self, u):
        return self.fmt.to_real(self.lookup(u))

    # ---- exact output distribution ----------------------------------------
    def all_outputs(self):
        """z for every distinct prefix of u that the block actually uses."""
        k = self.cfg.used_bits
        prefixes = np.arange(1 << k, dtype=np.uint64) << np.uint64(32 - k)
        return self.lookup_real(prefixes)

    def stats(self) -> dict:
        z = self.all_outputs()
        n = z.size
        m = z.mean()
        v = ((z - m) ** 2).mean()
        kurt = ((z - m) ** 4).mean() / v**2 - 3.0
        # exact KS distance of the discrete output CDF against Phi
        zs = np.sort(z)
        F_hi = np.arange(1, n + 1) / n
        F_lo = np.arange(0, n) / n
        Phi = _cdf(zs)
        ks = max(np.abs(F_hi - Phi).max(), np.abs(F_lo - Phi).max())
        # tail mass beyond |z| >= 2 and 3 vs the true normal
        tail = {t: (np.count_nonzero(np.abs(z) >= t) / n, 2 * (1 - _N.cdf(t))) for t in (2.0, 3.0)}
        # pointwise error |z_hw(u) - Phi^-1(u)| on a common 2^EVAL_BITS grid so
        # configs with different used_bits are judged against the same truth.
        # The max is dominated by the unbounded tail, so also report the RMS
        # and the 99th percentile.
        k = EVAL_BITS
        u_mid = (np.arange(1 << k) + 0.5) / (1 << k)
        z_eval = self.lookup_real((np.arange(1 << k, dtype=np.uint64) << np.uint64(32 - k)) | np.uint64(1 << (31 - k)))
        err = np.abs(z_eval - _inv_cdf(u_mid))
        return dict(
            name=self.cfg.name, rom_bits=self.cfg.rom_bits(), zmax=float(np.abs(z).max()),
            mean=float(m), var=float(v), ex_kurtosis=float(kurt), ks=float(ks),
            tail2=tail[2.0], tail3=tail[3.0], max_abs_err=float(err.max()),
            p99_err=float(np.percentile(err, 99)), rms_err=float(np.sqrt((err**2).mean())),
        )

    def exact_call_price(self, s0, k_strike, r, sigma, T) -> float:
        """Discounted E[max(S_T-K,0)] under the *hardware* Z distribution,
        with exact (float) exp. Isolates the bias caused by this block alone."""
        z = self.all_outputs()
        st = s0 * np.exp((r - 0.5 * sigma**2) * T + sigma * math.sqrt(T) * z)
        return math.exp(-r * T) * np.maximum(st - k_strike, 0.0).mean()

    # ---- export for RTL / testbench ---------------------------------------
    def write_rom_sv(self, path: Path, module: str = "gauss_lut_rom") -> None:
        """Synthesizable case-statement ROM of the positive half-table."""
        if self.cfg.mode != "rom":
            raise NotImplementedError("sv export for pwl pending")
        a, w = self.cfg.addr_bits, self.cfg.out_width
        lines = [
            f"// Generated by model/gauss_lut.py — do not edit. {self.cfg.name}",
            f"// Positive half of Phi^-1 at cell midpoints p=(addr+0.5)/2^{a}, format {self.fmt}.",
            f"module {module} #(parameter int ADDR_BITS = {a}, parameter int OUT_WIDTH = {w}) (",
            f"  input  logic [ADDR_BITS-2:0] j,",
            f"  output logic [OUT_WIDTH-1:0] mag",
            ");",
            "  always_comb begin",
            "    unique case (j)",
        ]
        for j, v in enumerate(self.rom):
            lines.append(f"      {a-1}'d{j}: mag = {w}'h{self.fmt.to_hex(v)};")
        lines += ["      default: mag = '0;", "    endcase", "  end", "endmodule", ""]
        path.write_text("\n".join(lines))

    def write_rom_hex(self, path: Path) -> None:
        path.write_text("\n".join(self.fmt.to_hex(v) for v in self.rom) + "\n")


def _round_shift_even(x, shift):
    """(x / 2**shift) with round-half-to-even on int64 arrays."""
    x = np.asarray(x, dtype=np.int64)
    if shift == 0:
        return x
    q = x >> shift
    rem = x - (q << shift)
    half = 1 << (shift - 1)
    up = (rem > half) | ((rem == half) & ((q & 1) == 1))
    return q + up.astype(np.int64)


def bs_call(s0, k, r, sigma, T) -> float:
    d1 = (math.log(s0 / k) + (r + 0.5 * sigma**2) * T) / (sigma * math.sqrt(T))
    d2 = d1 - sigma * math.sqrt(T)
    return s0 * _N.cdf(d1) - k * math.exp(-r * T) * _N.cdf(d2)


# Representative option grid (S0=100, T=1y, r=5%). Matches the proposal's
# "several representative option inputs"; OTM + high-vol rows are tail-sensitive.
OPTION_GRID = [
    ("ITM  K=80  s=0.2", 100.0, 80.0, 0.05, 0.2, 1.0),
    ("ATM  K=100 s=0.2", 100.0, 100.0, 0.05, 0.2, 1.0),
    ("OTM  K=120 s=0.2", 100.0, 120.0, 0.05, 0.2, 1.0),
    ("ATM  K=100 s=0.6", 100.0, 100.0, 0.05, 0.6, 1.0),
    ("OTM  K=150 s=0.6", 100.0, 150.0, 0.05, 0.6, 1.0),
]


def sweep(configs):
    rows = []
    for cfg in configs:
        lut = GaussLut(cfg)
        s = lut.stats()
        for label, *args in OPTION_GRID:
            ref = bs_call(*args)
            s[f"bias[{label}]"] = 100.0 * (lut.exact_call_price(*args) - ref) / ref
        rows.append(s)
    return rows


def _print_table(rows):
    keys = ["name", "rom_bits", "zmax", "var", "ex_kurtosis", "ks", "rms_err", "p99_err", "max_abs_err"]
    print(f"{'name':<24}" + " | ".join(f"{k:>11}" for k in keys[1:]))
    for r in rows:
        print(f"{r['name']:<24}" + " | ".join(f"{r[k]:>11}" if isinstance(r[k], int) else f"{r[k]:>11.5f}" for k in keys[1:]))
    print("\nTail mass P(|z|>=t): hardware vs normal")
    for r in rows:
        print(f"  {r['name']:<24} t=2: {r['tail2'][0]:.5f} vs {r['tail2'][1]:.5f}   t=3: {r['tail3'][0]:.6f} vs {r['tail3'][1]:.6f}")
    print("\nExact call-price bias from the Gaussian block alone (% of Black-Scholes price):")
    labels = [k for k in rows[0] if k.startswith("bias[")]
    print(f"  {'config':<24}" + "".join(f"{l[5:-1]:>20}" for l in labels))
    for r in rows:
        print(f"  {r['name']:<24}" + "".join(f"{r[l]:>+20.3f}" for l in labels))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--export", type=Path, help="write gauss_lut_rom.sv/.hex for --addr-bits/--frac-bits into this dir")
    ap.add_argument("--addr-bits", type=int, default=8)
    ap.add_argument("--out-width", type=int, default=16)
    ap.add_argument("--frac-bits", type=int, default=12)
    args = ap.parse_args()

    if args.export:
        cfg = GaussLutConfig(args.addr_bits, args.out_width, args.frac_bits)
        lut = GaussLut(cfg)
        args.export.mkdir(parents=True, exist_ok=True)
        lut.write_rom_sv(args.export / "gauss_lut_rom.sv")
        lut.write_rom_hex(args.export / "gauss_lut_rom.hex")
        print(f"wrote {cfg.name} ROM to {args.export}")
        return

    configs = [GaussLutConfig(a, 16, 12) for a in (6, 8, 10, 12)]
    configs += [GaussLutConfig(10, 16, f) for f in (8, 10)]
    configs += [GaussLutConfig(a, 16, 12, "pwl", 6) for a in (6, 8)]
    _print_table(sweep(configs))


if __name__ == "__main__":
    main()
