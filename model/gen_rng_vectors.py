"""Generate per-edge RNG control/output/state vectors (never edit by hand).

Each row: rst_n seed_load run seed_state u_valid u state_after.
Drive inputs before the rising edge; expectations describe post-edge registers.
"""
import argparse
from pathlib import Path
import random

from rng_lane import RngLane, pack_state

DEFAULT_OUT = Path(__file__).resolve().parents[1] / "tb/vectors/rng_lane.hex"


def stimuli(random_cycles=4096, seed=382):
    rng = random.Random(seed)
    a = pack_state((1, 2, 3, 4))
    b = pack_state((0xFFFFFFFF, 0x80000000, 0x12345678, 0xABCDEF01))
    yield 0, 1, 1, a                 # reset wins over load and run
    yield 1, 0, 1, 0                 # no output before a valid seed
    yield 1, 1, 1, a                 # load wins over run
    for _ in range(128):
        yield 1, 0, 1, b             # seed bus ignored without load
    for _ in range(7):
        yield 1, 0, 0, b             # pause
    for _ in range(64):
        yield 1, 0, 1, 0             # resume without skipping samples
    yield 1, 1, 0, a                 # reproducible reseed
    for _ in range(16):
        yield 1, 0, 1, 0
    yield 1, 1, 1, b                 # reseed during active run
    for _ in range(32):
        yield 1, 0, 1, 0
    yield 1, 1, 1, 0                 # invalid zero seed replaces old state
    for _ in range(8):
        yield 1, 0, 1, a             # zero must not produce valid zeros
    yield 1, 1, 1, b                 # recover by loading a nonzero seed
    yield 1, 0, 1, 0
    yield 0, 0, 1, 0                 # reset during operation
    yield 1, 0, 1, b                 # reset requires a fresh seed
    # Each one-hot seed, including high bits, plus all-ones wrap stress.
    for state in [(1 << bit,) + (0,) * 3 for bit in (0, 31)]:
        yield 1, 1, 0, pack_state(state)
        for _ in range(8):
            yield 1, 0, 1, 0
    for word in range(1, 4):
        state = [0] * 4
        state[word] = 0x80000000
        yield 1, 1, 1, pack_state(state)
        for _ in range(8):
            yield 1, 0, 1, 0
    yield 1, 1, 1, (1 << 128) - 1
    for _ in range(32):
        yield 1, 0, 1, 0
    for _ in range(random_cycles):
        yield int(rng.randrange(64) != 0), int(rng.randrange(16) == 0), rng.randrange(2), (
            0 if rng.randrange(16) == 0 else rng.getrandbits(128))
    yield 1, 0, 0, 0                 # verify no trailing valid on pause


def vector_text(random_cycles=4096, seed=382):
    lane = RngLane()
    rows = []
    for rst_n, load, run, packed in stimuli(random_cycles, seed):
        valid, u = lane.tick(rst_n=rst_n, seed_load=load, run=run, seed_state=packed)
        rows.append(f"{rst_n:x} {load:x} {run:x} {packed:032x} {int(valid):x} "
                    f"{u:08x} {pack_state(lane.state):032x}\n")
    return "".join(rows)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--random-cycles", type=int, default=4096)
    ap.add_argument("--seed", type=int, default=382)
    args = ap.parse_args()
    if args.random_cycles < 0:
        ap.error("--random-cycles must be nonnegative")
    contents = vector_text(args.random_cycles, args.seed)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(contents, encoding="ascii")
    print(f"wrote {len(contents.splitlines())} cycles to {args.out}")


if __name__ == "__main__":
    main()
