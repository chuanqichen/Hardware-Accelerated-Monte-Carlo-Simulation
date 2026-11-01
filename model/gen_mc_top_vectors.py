"""Create integrated top expectations from PR #4's unmodified lane model.

Run from repo root: python model/gen_mc_top_vectors.py
The trace contains u,z,x,S_T,p,sat_x,sat_s for each accepted trial. Metadata
contains A,B,K,seed,N,raw payoff sum,status. No pricing arithmetic is duplicated.
"""
import argparse
from pathlib import Path

from gauss_lut import OPTION_GRID
from mc_lane import run_lane, trace_lane
from price_dp import option_to_regs
from rng_lane import pack_state


def cases():
    seeds = [pack_state((0x12345678, 0x9ABCDEF0, 0x0F1E2D3C, 0x4B5A6978)),
             pack_state((1, 2, 3, 4)), pack_state((0xFFFFFFFF, 0x80000000, 7, 19))]
    atm = option_to_regs(100, 100, .05, .2, 1)
    for n in (1, 100, 1000, 10000):
        yield (*atm, seeds[0], n)
    for seed in seeds:
        for _, *option in OPTION_GRID:
            yield (*option_to_regs(*option), seed, 1000)
    # Exercise positive/negative x saturation and exp saturation, then a normal
    # run to detect stale sticky status across the LOAD clear edge.
    yield ((1 << 17)-1, 0xFFFF, 0, seeds[0], 128)
    yield (-(1 << 17), 0xFFFF, 0, seeds[0], 128)
    yield (*atm, seeds[0], 100)


def generate(out: Path):
    out.mkdir(parents=True, exist_ok=True)
    n_cases = n_trials = 0
    with (out / "mc_top_cases.hex").open("w") as meta, (out / "mc_top_trace.hex").open("w") as trace:
        for a, b, k, seed, n in cases():
            result = run_lane(a, b, k, seed, n)
            t = trace_lane(a, b, k, seed, n)
            status = 1 | (int(result["sat_x"]) << 1) | (int(result["sat_s"]) << 2) | (int(result["acc_overflow"]) << 3)
            meta.write(f"{a & 0x3ffff:05x} {b:04x} {k:06x} {seed:032x} {n:08x} {result['payoff_sum']:016x} {status:02x}\n")
            for i in range(n):
                trace.write(f"{int(t['u'][i]):08x} {int(t['z'][i]) & 0xffff:04x} {int(t['x'][i]) & 0x3ffff:05x} "
                            f"{int(t['s_t'][i]):06x} {int(t['p'][i]):06x} {int(t['sat_x'][i]):x} {int(t['sat_s'][i]):x}\n")
            n_cases += 1
            n_trials += n
    print(f"Generated {n_cases} integrated cases, {n_trials} trial traces from mc_lane.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, default=Path("tb/vectors"))
    generate(parser.parse_args().out)
