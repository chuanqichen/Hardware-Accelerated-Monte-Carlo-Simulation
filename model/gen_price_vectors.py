"""Generate test vectors for rtl/exp2_unit.sv, rtl/price_dp.sv and rtl/accumulator.sv.

  exp2_k<K>.hex        every x (2^18 lines): "xxxxx ssssss f"  (x, expected S_T, sat_s)
  price_dp_k<K>.hex    groups of trials sharing one configuration (A, B, K are static
                       during a run, so they are not pipelined in hardware):
                         "0 aaaaa bbbb kkkkkk"   new configuration (TB drains first)
                         "1 zzzz pppppp f"       trial: z, expected p, flags {sat_s,sat_x}
  accumulator_w<W>.hex one line per cycle: "c v pppppp f ssss..ss cccccccc g"
                       inputs clear, valid, p, flags {sat_s,sat_x}; then the expected
                       registers after that edge: sum, count, {sat_s,sat_x,overflow}
  accumulator_l<L>_w<W>.hex   the same for L = 2, 4 lanes. Line:
                       "c vmask p_packed f_packed ssss..ss cccccccc g"
                       vmask     L bits, bit i = lane i valid
                       p_packed  L*22 bits, lane i in bits [22*i +: 22]
                       f_packed  2*L bits, lane i: bit 2*i = sat_x, bit 2*i+1 = sat_s
                       Expected values include the adder-tree latency ceil(log2 L)
                       (price_dp.accumulate default), i.e. the registers after each edge.

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


def _acc_lines(path: Path, lanes, clear, valid, p, sat_x, sat_s, exp):
    with path.open("w") as f:
        for t in range(len(clear)):
            vm = sum(int(valid[t][i]) << i for i in range(lanes))
            pp = sum(int(p[t][i]) << (22 * i) for i in range(lanes))
            ff = sum((int(sat_x[t][i]) | int(sat_s[t][i]) << 1) << (2 * i) for i in range(lanes))
            s_, c, ovf, sx, ss = exp[t]
            f.write(f"{int(clear[t])} {_h(vm, lanes)} {_h(pp, 22 * lanes)} {_h(ff, 2 * lanes)} "
                    f"{_h(s_, 64)} {_h(c, 32)} {int(ss) * 4 + int(sx) * 2 + int(ovf)}\n")


def write_acc_lanes(out: Path, rng, lanes: int, sum_width: int, random_cycles: int) -> Path:
    """Multi-lane accumulator vectors (see module docstring for the line format)."""
    tree_lat = (lanes - 1).bit_length()
    mx = pd.ST_FMT.max_raw
    segs = []     # (clear, valid, p, sat_x, sat_s) blocks, concatenated at the end

    def block(n, valid, p, sx=None, ss=None, clear=None):
        z = np.zeros((n, lanes), bool)
        segs.append((np.zeros(n, bool) if clear is None else clear, valid, p,
                     z if sx is None else sx, z if ss is None else ss))

    def idle(n):
        block(n, np.zeros((n, lanes), bool), np.zeros((n, lanes), np.int64))

    if sum_width == 64:
        # (a) random streams: random per-lane valid, clears (some back to back), sat flags
        n = random_cycles
        clear = rng.random(n) < 0.01
        clear[[0, n // 2, n // 2 + 1]] = True
        block(n, rng.random((n, lanes)) < 0.7, rng.integers(0, 1 << 22, (n, lanes)),
              rng.random((n, lanes)) < 0.01, rng.random((n, lanes)) < 0.01, clear)
        # (b) controller-style runs: clear, floor(N/L) full beats, one masked beat, drain
        for N in (101, 1001, 10003):
            full, rem = divmod(N, lanes)
            nb = full + (1 if rem else 0)
            valid = np.ones((nb, lanes), bool)
            if rem:
                valid[-1, rem:] = False                      # low lanes carry the remainder
            clear = np.zeros(nb + 1, bool)
            clear[0] = True
            block(nb + 1, np.vstack([np.zeros((1, lanes), bool), valid]),
                  rng.integers(0, 1 << 22, (nb + 1, lanes)),
                  rng.random((nb + 1, lanes)) < 0.002, rng.random((nb + 1, lanes)) < 0.002, clear)
            idle(tree_lat + 2)
        # (c) sustained full-rate beats of maximum p
        n = 2000
        clear = np.zeros(n, bool)
        clear[0] = True
        block(n, np.ones((n, lanes), bool), np.full((n, lanes), mx), clear=clear)
        idle(tree_lat + 2)
    else:
        # overflow: mostly max payoffs so the 32-bit sum wraps; clears let it wrap again
        n = 5000
        clear = np.zeros(n, bool)
        clear[[0, n // 3, n // 3 + 1]] = True
        clear[rng.integers(1, n, 3)] = True
        p = np.where(rng.random((n, lanes)) < 0.9, mx, rng.integers(0, 1 << 22, (n, lanes)))
        block(n, rng.random((n, lanes)) < 0.9, p,
              rng.random((n, lanes)) < 0.002, rng.random((n, lanes)) < 0.002, clear)
        idle(tree_lat + 2)
    clear, valid, p, sx, ss = (np.concatenate([sg[i] for sg in segs]) for i in range(5))
    exp = pd.accumulate(p, valid, clear, sx, ss, sum_width)
    if sum_width == 64:       # each controller-style run ends with trial_count == N exactly
        pos = random_cycles
        for N in (101, 1001, 10003):
            nb = -(-N // lanes) + 1
            pos += nb + tree_lat + 2
            assert exp[pos - 1][1] == N, (lanes, N, exp[pos - 1][1])
    path = out / f"accumulator_l{lanes}_w{sum_width}.hex"
    _acc_lines(path, lanes, clear, valid, p, sx, ss, exp)
    print(f"wrote {len(clear)} accumulator cycles to {path} (overflow seen: {any(e[2] for e in exp)})")
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
    rng_l = np.random.default_rng(a.seed + 1)      # separate stream: one-lane files stay unchanged
    for lanes in (2, 4):
        for w in (64, 32):
            write_acc_lanes(a.out, rng_l, lanes, w, 10000)


if __name__ == "__main__":
    main()
