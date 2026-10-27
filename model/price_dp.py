"""Bit-accurate model of the pricing datapath (price_dp) and the accumulator.

One trial, all values are raw two's-complement / unsigned ints (see fxp.py):

  S1  acc = (A << 14) + B * z          fused multiply-add, Q5.26 (34b signed)
         A Q5.12 is shifted 14 so its binary point lines up with B*z
         (UQ2.14 * Q3.12 -> 14 + 12 = 26 fraction bits)
  S2  x   = sat18(round_even(acc, 14)) Q5.12; sat_x if the clamp fired
         One rounding of the whole sum. (round(Bz) + A would differ by 1 LSB
         on exact ties when A is odd - this block defines single rounding.)
  S3  y   = x * LOG2E                  e^x = 2^y, y has 12 + LOG2E_FRAC fraction bits
      n   = floor(y)                   integer part  -> shift amount
      f   = y - n in [0, 1)            fraction part -> ROM address (top k bits)
  S4  rom = 2^((addr + 0.5) / 2^k)     UQ1.16, value in [1, 2), cell midpoint
  S5  S_T = round_even(rom * 2^n)      UQ14.8; n >= 14 -> clamp to max, sat_s;
                                       very negative n -> rounds to 0 (no flag)
  S6  p   = S_T > K ? S_T - K : 0      UQ14.8, exact

Accumulator: payoff_sum += sum of valid p, trial_count += popcount(valid),
sticky acc_overflow / sat_x / sat_s, clear has priority over a same-cycle add.

Run as a script for a demo trace and the EXP_ADDR_BITS sweep; import for unit
tests and testbench vector generation (gen_price_vectors.py).
"""
from __future__ import annotations

import argparse
import math
from dataclasses import dataclass
from pathlib import Path

import numpy as np

from fxp import Fxp, round_shift_even
from gauss_lut import OPTION_GRID, GaussLut, GaussLutConfig, bs_call

# Register formats (docs/Lane_Interface_Spec.md section 3)
A_FMT = Fxp(18, 12)
B_FMT = Fxp(16, 14, signed=False)
Z_FMT = Fxp(16, 12)
X_FMT = Fxp(18, 12)
ST_FMT = Fxp(22, 8, signed=False)      # also K and p
ACC_FRAC = B_FMT.frac + Z_FMT.frac      # 26
A_SHIFT = ACC_FRAC - A_FMT.frac         # 14
ST_MAX_N = 14                           # 2^14 is the first value S_T cannot hold


@dataclass(frozen=True)
class PriceDpConfig:
    exp_addr_bits: int = 10   # k: 2^f ROM has 2^k entries
    rom_frac: int = 16        # ROM entries are UQ1.rom_frac
    log2e_frac: int = 16      # LOG2E constant fraction bits
    mul_stages: int = 1       # registers after the MAC (DC retimes them into the tree)

    @property
    def lat_exp(self) -> int:
        return 3              # S3, S4, S5

    @property
    def lat_dp(self) -> int:
        return self.mul_stages + 1 + self.lat_exp + 1   # S1.., S2, S3-S5, S6

    @property
    def log2e(self) -> int:
        return int(round(math.log2(math.e) * (1 << self.log2e_frac)))

    @property
    def y_frac(self) -> int:
        return X_FMT.frac + self.log2e_frac

    @property
    def rom_width(self) -> int:
        return self.rom_frac + 1

    @property
    def name(self) -> str:
        return f"k{self.exp_addr_bits}_r{self.rom_frac}_l{self.log2e_frac}"


def exp_rom(cfg: PriceDpConfig) -> np.ndarray:
    """2^f at each cell midpoint, rounded to UQ1.rom_frac."""
    n = 1 << cfg.exp_addr_bits
    mid = (np.arange(n) + 0.5) / n
    return np.rint(np.exp2(mid) * (1 << cfg.rom_frac)).astype(np.int64)


# ---- stages ----------------------------------------------------------------
def mac(a, b, z):
    """S1: (A << 14) + B*z, Q5.26."""
    a, b, z = (np.asarray(v, dtype=np.int64) for v in (a, b, z))
    return (a << A_SHIFT) + b * z


def round_x(acc):
    """S2: narrow Q5.26 -> Q5.12 (round-half-even, saturate). Returns (x, sat_x)."""
    return X_FMT.saturate(round_shift_even(acc, A_SHIFT))


def exp_fx(x, cfg: PriceDpConfig, rom: np.ndarray | None = None) -> dict:
    """S3-S5: x Q5.12 -> S_T UQ14.8 by range reduction. Returns every intermediate."""
    if rom is None:
        rom = exp_rom(cfg)
    x = np.asarray(x, dtype=np.int64)
    y = x * cfg.log2e
    n = y >> cfg.y_frac
    f = y - (n << cfg.y_frac)
    addr = f >> (cfg.y_frac - cfg.exp_addr_bits)
    r = rom[addr]

    # S_T raw (8 fraction bits) = r * 2^(n - rom_frac + 8)
    sh = n - cfg.rom_frac + ST_FMT.frac            # >0: shift left, <=0: round right
    max_rsh = cfg.rom_width + 1                     # beyond this everything rounds to 0
    s_t = np.zeros_like(x)
    left = sh > 0
    s_t[left] = r[left] << np.minimum(sh[left], 30)
    for s in range(0, max_rsh + 1):                 # few distinct shifts -> loop is cheap
        m = (~left) & (np.minimum(-sh, max_rsh) == s)
        if np.any(m):
            s_t[m] = round_shift_even(r[m], s)
    sat_s = n >= ST_MAX_N
    s_t = np.where(sat_s, ST_FMT.max_raw, s_t)
    return dict(y=y, n=n, addr=addr, rom=r, s_t=s_t, sat_s=sat_s)


def payoff(s_t, k):
    """S6: max(S_T - K, 0) in UQ14.8."""
    s_t, k = np.asarray(s_t, dtype=np.int64), np.asarray(k, dtype=np.int64)
    return np.where(s_t > k, s_t - k, 0)


def price_dp(a, b, k, z, cfg: PriceDpConfig = PriceDpConfig(), rom: np.ndarray | None = None) -> dict:
    """Whole block for one or many trials. Returns the per-trial trace (raw ints)."""
    acc = mac(a, b, z)
    x, sat_x = round_x(acc)
    e = exp_fx(x, cfg, rom)
    p = payoff(e["s_t"], k)
    return dict(acc=acc, x=x, sat_x=sat_x, n=e["n"], addr=e["addr"], rom=e["rom"],
                s_t=e["s_t"], sat_s=e["sat_s"], p=p)


# ---- accumulator -----------------------------------------------------------
def accumulate(p, valid, clear=None, sat_x=None, sat_s=None, sum_width: int = 64):
    """Cycle-by-cycle accumulator. p/valid/sat_* are [cycles, lanes] (or [cycles]).

    Returns a list of per-cycle register states *after* that clock edge:
    (payoff_sum, trial_count, acc_overflow, sat_x_sticky, sat_s_sticky).
    """
    p = np.atleast_2d(np.asarray(p, dtype=np.int64).T).T
    valid = np.atleast_2d(np.asarray(valid, dtype=bool).T).T
    cycles = p.shape[0]
    clear = np.zeros(cycles, bool) if clear is None else np.asarray(clear, bool)
    sat_x = np.zeros_like(valid) if sat_x is None else np.atleast_2d(np.asarray(sat_x, bool).T).T
    sat_s = np.zeros_like(valid) if sat_s is None else np.atleast_2d(np.asarray(sat_s, bool).T).T
    mask = (1 << sum_width) - 1
    s = cnt = 0
    ovf = sx = ss = False
    out = []
    for t in range(cycles):
        if clear[t]:
            s = cnt = 0
            ovf = sx = ss = False
        else:
            v = valid[t]
            total = s + int(p[t][v].sum())
            ovf = ovf or total > mask
            s = total & mask
            cnt = (cnt + int(v.sum())) & 0xFFFFFFFF
            sx = sx or bool(np.any(sat_x[t] & v))
            ss = ss or bool(np.any(sat_s[t] & v))
        out.append((s, cnt, ovf, sx, ss))
    return out


# ---- software side ---------------------------------------------------------
def option_to_regs(s0, k, r, sigma, T):
    """Option parameters -> raw A, B, K register values (what the host writes)."""
    a = math.log(s0) + (r - 0.5 * sigma**2) * T
    b = sigma * math.sqrt(T)
    return int(A_FMT.quantize(a)), int(B_FMT.quantize(b)), int(ST_FMT.quantize(k))


def price_from_sum(payoff_sum, trial_count, r, T) -> float:
    """What the host does after done: average, undo the 2^8 scale, discount."""
    return math.exp(-r * T) * payoff_sum / (ST_FMT.scale * trial_count)


def exact_price(s0, k, r, sigma, T, cfg: PriceDpConfig, lut: GaussLut) -> float:
    """Price with every z the Gaussian table can produce, each equally likely.

    No Monte Carlo noise: this is the systematic value the hardware converges to.
    """
    a, b, kk = option_to_regs(s0, k, r, sigma, T)
    z = lut.fmt.quantize(lut.all_outputs())
    p = price_dp(a, b, kk, z, cfg)["p"]
    return price_from_sum(int(p.sum()), p.size, r, T)


# ---- RTL export --------------------------------------------------------------
def write_exp_rom_sv(cfg: PriceDpConfig, path: Path, module: str = "exp2_rom") -> None:
    """Synthesizable case-statement ROM of 2^f at cell midpoints."""
    k, w = cfg.exp_addr_bits, cfg.rom_width
    fmt = Fxp(w, cfg.rom_frac, signed=False)
    lines = [
        f"// Generated by model/price_dp.py - do not edit. {cfg.name}",
        f"// 2^((addr+0.5)/2^{k}) for addr in [0, 2^{k}), format {fmt}.",
        f"module {module} #(parameter int ADDR_BITS = {k}, parameter int OUT_WIDTH = {w}) (",
        "  input  logic [ADDR_BITS-1:0] addr,",
        "  output logic [OUT_WIDTH-1:0] val",
        ");",
        "  always_comb begin",
        "    case (addr)",
    ]
    for i, v in enumerate(exp_rom(cfg)):
        lines.append(f"      {k}'d{i}: val = {w}'h{fmt.to_hex(v)};")
    lines += ["      default: val = '0;", "    endcase", "  end", "endmodule", ""]
    path.write_text("\n".join(lines))


# ---- analysis ----------------------------------------------------------------
def exp_error(cfg: PriceDpConfig) -> dict:
    """Exhaustive exp error over every x with 64 <= S_T < 2^14.

    Below 64 the output LSB (2^-8) itself is > 6e-5 relative and hides the table
    error, so this range measures the ROM + log2e error, not output rounding."""
    x = np.arange(X_FMT.min_raw, X_FMT.max_raw + 1, dtype=np.int64)
    s_t = exp_fx(x, cfg)["s_t"]
    exact = np.exp(X_FMT.to_real(x))
    ok = (exact >= 64.0) & (exact < 2.0**ST_MAX_N)
    rel = np.abs(ST_FMT.to_real(s_t[ok]) - exact[ok]) / exact[ok]
    return dict(max_rel=float(rel.max()), mean_rel=float(rel.mean()), bias_rel=float(
        ((ST_FMT.to_real(s_t[ok]) - exact[ok]) / exact[ok]).mean()))


def sweep(ks=(6, 7, 8, 9, 10, 11, 12), gauss_bits: int = 10):
    lut = GaussLut(GaussLutConfig(gauss_bits, 16, 12))
    print(f"exp (k = EXP_ADDR_BITS) sweep, Gaussian LUT ADDR_BITS={gauss_bits}")
    print(f"{'k':>3} {'rom bits':>9} {'max rel err':>12} {'mean rel err':>13} {'mean bias':>11}   "
          + "  ".join(f"{label.split()[0]+' '+label.split()[1]:>12}" for label, *_ in OPTION_GRID))
    for k in ks:
        cfg = PriceDpConfig(exp_addr_bits=k)
        e = exp_error(cfg)
        dp_bias = []
        for _, *args in OPTION_GRID:
            ref = lut.exact_call_price(*args)      # same z, float math -> isolates this block
            dp_bias.append(100.0 * (exact_price(*args, cfg, lut) - ref) / ref)
        print(f"{k:>3} {(1 << k) * cfg.rom_width:>9} {e['max_rel']:>12.2e} {e['mean_rel']:>13.2e} "
              f"{e['bias_rel']:>+11.2e}   " + "  ".join(f"{v:>+11.4f}%" for v in dp_bias))
    print("\nper-option columns: price bias caused by price_dp alone (fixed point + exp),")
    print("relative to the same Gaussian table with float math (includes A/B/K register rounding).")

    cfg = PriceDpConfig()
    print(f"\nend to end at {cfg.name} vs Black-Scholes (Gaussian LUT + price_dp together):")
    for label, *args in OPTION_GRID:
        ref = bs_call(*args)
        hw = exact_price(*args, cfg, lut)
        print(f"  {label:<18} BS {ref:9.4f}  hw {hw:9.4f}  bias {100*(hw-ref)/ref:+.3f}%")


def demo(cfg: PriceDpConfig = PriceDpConfig()):
    s0, k, r, sigma, T = 100.0, 100.0, 0.05, 0.2, 1.0
    a, b, kk = option_to_regs(s0, k, r, sigma, T)
    print(f"option S0={s0} K={k} r={r} sigma={sigma} T={T}")
    print(f"registers: A={a} ({A_FMT.to_real(a):.5f})  B={b} ({B_FMT.to_real(b):.5f})  K={kk}")
    print(f"config {cfg.name}: LOG2E={cfg.log2e}, LAT_DP={cfg.lat_dp}")
    zs = np.array([-2.0, -1.0, 0.0, 1.0, 2.0])
    z = Z_FMT.quantize(zs)
    t = price_dp(a, b, kk, z, cfg)
    print(f"{'z':>6} {'acc':>10} {'x':>8} {'n':>3} {'addr':>5} {'rom':>7} {'S_T':>10} {'p':>9}")
    for i in range(z.size):
        print(f"{zs[i]:>6.2f} {t['acc'][i]:>10} {X_FMT.to_real(t['x'][i]):>8.4f} {t['n'][i]:>3} "
              f"{t['addr'][i]:>5} {t['rom'][i]:>7} {ST_FMT.to_real(t['s_t'][i]):>10.4f} "
              f"{ST_FMT.to_real(t['p'][i]):>9.4f}")
    print()


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--export", type=Path, help="write exp2_rom.sv for --exp-addr-bits into this dir")
    ap.add_argument("--exp-addr-bits", type=int, default=PriceDpConfig.exp_addr_bits)
    args = ap.parse_args()
    cfg = PriceDpConfig(exp_addr_bits=args.exp_addr_bits)
    if args.export:
        args.export.mkdir(parents=True, exist_ok=True)
        write_exp_rom_sv(cfg, args.export / "exp2_rom.sv")
        print(f"wrote {cfg.name} exp ROM to {args.export}")
        return
    demo(cfg)
    sweep()


if __name__ == "__main__":
    main()
