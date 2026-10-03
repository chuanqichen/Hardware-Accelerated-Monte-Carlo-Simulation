"""Generate directed + random test vectors for rtl/gauss_lut.sv.

Writes tb/vectors/gauss_lut_<name>.hex with one "uuuuuuuu zzzz" pair per line
(u: 32-bit uniform in hex, z: expected OUT_WIDTH-bit two's-complement in hex).
Directed cases cover every address exactly once (exhaustive table check plus
symmetry), both extremes, and the half-way boundary; the rest are random.

    python3 model/gen_gauss_vectors.py --addr-bits 10 --random 10000
"""
from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np

from gauss_lut import GaussLut, GaussLutConfig


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--addr-bits", type=int, default=10)
    ap.add_argument("--out-width", type=int, default=16)
    ap.add_argument("--frac-bits", type=int, default=12)
    ap.add_argument("--random", type=int, default=10000)
    ap.add_argument("--seed", type=int, default=382)
    ap.add_argument("--out", type=Path, default=Path(__file__).resolve().parents[1] / "tb" / "vectors")
    a = ap.parse_args()

    cfg = GaussLutConfig(a.addr_bits, a.out_width, a.frac_bits)
    lut = GaussLut(cfg)
    k = cfg.addr_bits
    # directed: every address with a random low-bit pattern, plus corner words
    rng = np.random.default_rng(a.seed)
    low = rng.integers(0, 1 << (32 - k), size=1 << k, dtype=np.uint64)
    directed = (np.arange(1 << k, dtype=np.uint64) << np.uint64(32 - k)) | low
    corners = np.array([0, 0xFFFFFFFF, 0x7FFFFFFF, 0x80000000, 0x00000001], dtype=np.uint64)
    random = rng.integers(0, 1 << 32, size=a.random, dtype=np.uint64)
    u = np.concatenate([corners, directed, random])
    z = lut.lookup(u)

    a.out.mkdir(parents=True, exist_ok=True)
    path = a.out / f"gauss_lut_a{k}_w{a.out_width}_f{a.frac_bits}.hex"
    with path.open("w") as f:
        for ui, zi in zip(u, z):
            f.write(f"{int(ui):08x} {lut.fmt.to_hex(zi)}\n")
    print(f"wrote {u.size} vectors to {path}")


if __name__ == "__main__":
    main()
