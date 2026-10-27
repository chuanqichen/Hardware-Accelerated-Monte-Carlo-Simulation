"""Generate test vectors for rtl/exp2_unit.sv, rtl/price_dp.sv and rtl/accumulator.sv.

  exp2_k<K>.hex        every x (2^18 lines): "xxxxx ssssss f"  (x, expected S_T, sat_s)
  price_dp_k<K>.hex    groups of trials sharing one configuration (A, B, K are static
                       during a run, so they are not pipelined in hardware):
                         "0 aaaaa bbbb kkkkkk"   new configuration (TB drains first)
                         "1 zzzz pppppp f"       trial: z, expected p, flags {sat_s,sat_x}
  accumulator_w<W>.hex one line per cycle: "c v pppppp f ssss..ss cccccccc g"
                       inputs clear, valid, p, flags {sat_s,sat_x}; then the expected
                       registers after that edge: sum, count, {sat_s,sat_x,overflow}

    python3 model/gen_price_vectors.py --exp-addr-bits 10
"""
from __future__ import annotations

import argparse
import math
from pathlib import Path

import numpy as np

import price_dp as pd
from gauss_lut import OPTION_GRID


def _h(v, width):
    return format(int(v) & ((1 << width) - 1), f"0{(width + 3) // 4}x")


def write_exp(cfg, out: Path) -> Path:
    x = np.arange(pd.X_FMT.min_raw, pd.X_FMT.max_raw + 1, dtype=np.int64)
    e = pd.exp_fx(x, cfg)
    path = out / f"exp2_k{cfg.exp_addr_bits}.hex"
    with path.open("w") as f:
        for xi, si, fi in zip(x, e["s_t"], e["sat_s"]):
            f.write(f"{_h(xi, 18)} {_h(si, 22)} {int(fi)}\n")
    print(f"wrote {x.size} exp vectors to {path} (sat_s: {int(e['sat_s'].sum())})")
    return path


def price_groups(rng, n_random_groups: int, per_group: int):
    """(a, b, k, z_array) groups: directed first, then random."""
    groups = []
    zq = pd.Z_FMT.quantize
    # every option in the grid, with a sweep of z through and beyond the table range
    for _, s0, k, r, sigma, T in OPTION_GRID:
        a, b, kk = pd.option_to_regs(s0, k, r, sigma, T)
        groups.append((a, b, kk, zq(np.linspace(-4, 4, 161))))
    # fused-rounding ties: B*z exactly half an LSB of x, odd and even A
    for a in (0, 1, 2, 3, -1, -2):
        groups.append((a, 0x6000, 0, np.array([1, -1, 3, -3])))
    # B = 0.5 makes B*z a tie for every odd z. Near S_T = 8000 one LSB of x moves
    # S_T by ~2 LSB, so the rounding direction is visible at p, not just inside.
    odd_z = np.arange(-63, 64, 2)
    for a in range(pd.A_FMT.quantize(math.log(8000.0)), pd.A_FMT.quantize(math.log(8000.0)) + 8):
        groups.append((a, 0x2000, 0, odd_z))
    # sat_x at both ends; exp overflow (sat_s) and underflow
    groups.append((pd.A_FMT.max_raw, pd.B_FMT.max_raw, 0, np.array([pd.Z_FMT.max_raw, 0, pd.Z_FMT.min_raw])))
    groups.append((pd.A_FMT.min_raw, pd.B_FMT.max_raw, 0, np.array([pd.Z_FMT.min_raw, 0, pd.Z_FMT.max_raw])))
    groups.append((pd.A_FMT.quantize(9.0), pd.B_FMT.quantize(1.0), 0, zq(np.linspace(-1, 2, 49))))
    groups.append((pd.A_FMT.quantize(-5.0), pd.B_FMT.quantize(1.0), 0, zq(np.linspace(-3, 1, 33))))
    # payoff boundary: K equal to, one below and one above S_T for z = 0
    a, b, _ = pd.option_to_regs(100, 100, 0.05, 0.2, 1.0)
    s0 = int(pd.price_dp(a, b, 0, 0)["s_t"])
    for kk in (s0 - 1, s0, s0 + 1, 0, pd.ST_FMT.max_raw):
        groups.append((a, b, kk, np.array([0, 0, 1, -1])))
    # random: realistic options and full-range raw registers
    for g in range(n_random_groups):
        if g % 2 == 0:
            s0r = float(rng.uniform(1, 2000))
            a, b, kk = pd.option_to_regs(s0r, float(rng.uniform(0.5, 1.5)) * s0r,
                                         float(rng.uniform(0, 0.1)), float(rng.uniform(0.05, 1.0)),
                                         float(rng.uniform(0.1, 5.0)))
        else:
            a = int(rng.integers(pd.A_FMT.min_raw, pd.A_FMT.max_raw + 1))
            b = int(rng.integers(0, pd.B_FMT.max_raw + 1))
            kk = int(rng.integers(0, pd.ST_FMT.max_raw + 1))
        z = rng.integers(pd.Z_FMT.min_raw, pd.Z_FMT.max_raw + 1, size=per_group)
        groups.append((a, b, kk, z))
    return groups


def write_price(cfg, out: Path, rng, n_random_groups: int, per_group: int) -> Path:
    path = out / f"price_dp_k{cfg.exp_addr_bits}.hex"
    n = nsx = nss = 0
    rom = pd.exp_rom(cfg)
    with path.open("w") as f:
        for a, b, kk, z in price_groups(rng, n_random_groups, per_group):
            t = pd.price_dp(a, b, kk, z, cfg, rom)
            f.write(f"0 {_h(a, 18)} {_h(b, 16)} {_h(kk, 22)}\n")
            for zi, pi, sx, ss in zip(z, t["p"], t["sat_x"], t["sat_s"]):
                f.write(f"1 {_h(zi, 16)} {_h(pi, 22)} {int(ss) * 2 + int(sx)}\n")
            n += z.size
            nsx += int(t["sat_x"].sum())
            nss += int(t["sat_s"].sum())
    print(f"wrote {n} price_dp trials to {path} (sat_x: {nsx}, sat_s: {nss})")
    return path


def write_acc(out: Path, rng, sum_width: int, cycles: int) -> Path:
    path = out / f"accumulator_w{sum_width}.hex"
    if sum_width < 64:      # overflow test: mostly max payoffs so the sum wraps quickly
        p = np.where(rng.random(cycles) < 0.9, pd.ST_FMT.max_raw, rng.integers(0, 1 << 22, cycles))
    else:
        p = rng.integers(0, 1 << 22, size=cycles)
    valid = rng.random(cycles) < 0.8
    clear = np.zeros(cycles, bool)
    clear[[0, cycles // 3, cycles // 3 + 1]] = True
    clear[rng.integers(1, cycles, 3)] = True
    sat_x = rng.random(cycles) < 0.002
    sat_s = rng.random(cycles) < 0.002
    exp = pd.accumulate(p, valid, clear, sat_x, sat_s, sum_width)
    with path.open("w") as f:
        for t in range(cycles):
            s, c, ovf, sx, ss = exp[t]
            f.write(f"{int(clear[t])} {int(valid[t])} {_h(p[t], 22)} {int(sat_s[t]) * 2 + int(sat_x[t])} "
                    f"{_h(s, 64)} {_h(c, 32)} {int(ss) * 4 + int(sx) * 2 + int(ovf)}\n")
    print(f"wrote {cycles} accumulator cycles to {path} (overflow seen: {any(e[2] for e in exp)})")
    return path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--exp-addr-bits", type=int, default=10)
    ap.add_argument("--groups", type=int, default=100, help="random price_dp configurations")
    ap.add_argument("--per-group", type=int, default=100, help="trials per random configuration")
    ap.add_argument("--acc-cycles", type=int, default=20000)
    ap.add_argument("--seed", type=int, default=382)
    ap.add_argument("--out", type=Path, default=Path(__file__).resolve().parents[1] / "tb" / "vectors")
    a = ap.parse_args()

    cfg = pd.PriceDpConfig(exp_addr_bits=a.exp_addr_bits)
    rng = np.random.default_rng(a.seed)
    a.out.mkdir(parents=True, exist_ok=True)
    write_exp(cfg, a.out)
    write_price(cfg, a.out, rng, a.groups, a.per_group)
    write_acc(a.out, rng, 64, a.acc_cycles)
    write_acc(a.out, rng, 32, 5000)


if __name__ == "__main__":
    main()
