"""Bounded interface expectations for real lane replication and registered reduction."""
import argparse
from pathlib import Path

from gauss_lut import GaussLutConfig
from gen_mc_top_vectors import cases
from mc_array import array_seeds, run_array
from mc_lane import LaneConfig
from price_dp import PriceDpConfig


def generate(out, lanes, gauss_bits=10, exp_bits=10):
    cfg = LaneConfig(gauss=GaussLutConfig(gauss_bits, 16, 12), dp=PriceDpConfig(exp_addr_bits=exp_bits))
    corpus = list(cases())
    a, b, k, root, _ = corpus[0]
    corpus += [(a, b, k, root, n) for n in sorted({1, max(1, lanes-1), lanes, lanes+1, 31, 1001})]
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", newline="\n") as file:
        for a, b, k, root, n in corpus:
            result = run_array(a, b, k, root, n, lanes, cfg)
            seeds = sum(seed << (128*i) for i, seed in enumerate(array_seeds(root, lanes)))
            status = 1 | int(result["sat_x"]) << 1 | int(result["sat_s"]) << 2 | int(result["acc_overflow"]) << 3
            file.write(f"{a & 0x3ffff:05x} {b:04x} {k:06x} {seeds:0128x} {n:08x} {result['payoff_sum']:016x} {status:02x}\n")
    print(f"Generated lanes={lanes} a={gauss_bits} k={exp_bits} cases={len(corpus)} trials={sum(c[-1] for c in corpus)}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lanes", type=int, choices=(1, 2, 4), required=True)
    parser.add_argument("--gauss-bits", type=int, default=10, choices=range(6, 13))
    parser.add_argument("--exp-bits", type=int, default=10, choices=range(6, 13))
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    generate(args.out, args.lanes, args.gauss_bits, args.exp_bits)
