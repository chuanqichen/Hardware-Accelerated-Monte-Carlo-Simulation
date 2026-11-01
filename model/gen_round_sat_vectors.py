"""Generate directed + random test vectors for rtl/round_sat.sv.

Writes tb/vectors/round_sat_i<IN>_o<OUT>_s<SHIFT>_<s|u>.hex with one
"in out sat" triple per line (all hex; `in` is IN_WIDTH-bit two's complement
when signed). Directed cases are the tie / sign / saturation corners from
model/test_round_sat.py; the rest are random, with extra density around the
saturation boundaries where rounding and clamping interact.

    python3 model/gen_round_sat_vectors.py --in-width 34 --out-width 18 --shift 14 --signed
    python3 model/gen_round_sat_vectors.py --in-width 26 --out-width 16 --shift 8
"""
from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np

from fxp import Fxp, round_sat


def directed(in_fmt: Fxp, out_fmt: Fxp, shift: int) -> np.ndarray:
    s = 1 << shift
    half = s >> 1
    mx, mn = out_fmt.max_raw, out_fmt.min_raw
    cases = [0, in_fmt.max_raw, in_fmt.min_raw]
    # ties and near-ties around a few small quotients, both signs
    for q in (0, 1, 2, 3, -1, -2, -3):
        for d in (0, 1, half - 1, half, half + 1, s - 1):
            cases.append(q * s + d)
    # saturation boundaries: exactly max/min, +-1 LSB of the input, the tie just past
    for edge in (mx, mn):
        for d in (-s, -half - 1, -half, -half + 1, -1, 0, 1, half - 1, half, half + 1, s):
            cases.append(edge * s + d)
    x = np.array(cases, dtype=np.int64)
    return x[(x >= in_fmt.min_raw) & (x <= in_fmt.max_raw)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--in-width", type=int, default=34)
    ap.add_argument("--out-width", type=int, default=18)
    ap.add_argument("--shift", type=int, default=14)
    ap.add_argument("--signed", action="store_true", help="two's complement in/out (SIGNED=1)")
    ap.add_argument("--random", type=int, default=10000)
    ap.add_argument("--seed", type=int, default=382)
    ap.add_argument("--out", type=Path, default=Path(__file__).resolve().parents[1] / "tb" / "vectors")
    a = ap.parse_args()

    in_fmt = Fxp(a.in_width, 0, signed=a.signed)
    out_fmt = Fxp(a.out_width, 0, signed=a.signed)
    rng = np.random.default_rng(a.seed)

    full = rng.integers(in_fmt.min_raw, in_fmt.max_raw + 1, size=a.random, dtype=np.int64)
    near = []
    for edge in (out_fmt.max_raw, out_fmt.min_raw):
        near.append((edge << a.shift) + rng.integers(-(1 << (a.shift + 2)), 1 << (a.shift + 2),
                                                     size=a.random // 10, dtype=np.int64))
    x = np.concatenate([directed(in_fmt, out_fmt, a.shift), full, *near])
    x = x[(x >= in_fmt.min_raw) & (x <= in_fmt.max_raw)]
    out, sat = round_sat(x, a.shift, out_fmt)

    a.out.mkdir(parents=True, exist_ok=True)
    path = a.out / f"round_sat_i{a.in_width}_o{a.out_width}_s{a.shift}_{'s' if a.signed else 'u'}.hex"
    with path.open("w") as f:
        for xi, oi, si in zip(x, out, sat):
            f.write(f"{in_fmt.to_hex(xi)} {out_fmt.to_hex(oi)} {int(si)}\n")
    print(f"wrote {x.size} vectors to {path} (sat: {int(sat.sum())})")


if __name__ == "__main__":
    main()
