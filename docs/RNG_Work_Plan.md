# RNG milestone 1: xoshiro128++ lane

Implemented 2026-10-13; control choices below are proposed for team review.
Scope follows Project_Proposal.md: one single-step pricing lane first; no second
RNG frontend. The algorithm is xoshiro128++ 1.0, David Blackman and Sebastiano
Vigna (2019): https://prng.di.unimi.it/xoshiro128plusplus.c . Their canonical
source is public domain (CC0). This milestone implements next(), not jump().

## Algorithm and interface

Python state order is `(s0,s1,s2,s3)`; the RTL seed bus is
`seed_state={s3,s2,s1,s0}`. The output is
`rotl32((s0+s3) mod 2^32,7)+s0 mod 2^32`, using the pre-transition state.
The state uses the canonical XOR/shift updates and rotate-left by 11.
Every operation is unsigned modulo 2^32. Fixed-point saturation does not apply.

`rng_lane` has `clk`, `rst_n`, `seed_load`, `seed_state[127:0]`, `run`,
`u[31:0]`, and `u_valid`. Localparam `LAT_RNG=1`: a run accepted at a rising
edge produces the registered word/valid after that edge; a downstream register
consumes it at the following rising edge. One word per cycle, no back-pressure.

## Proposed control contract

Priority is **reset > seed_load > run > hold**.

- Reset asserts asynchronously and clears all state, u, and u_valid. Deassertion
  must be synchronized by the future mc_top; rng_lane does not synchronize it.
- A seed_load edge copies all four words, clears u/u_valid, and does not advance
  or generate even when run is high. First sample uses the loaded state on the
  next run edge. Repeated seed loads repeatedly replace the state.
- A run edge with nonzero state registers the canonical output and next state.
- Pause (`run=0`) preserves state and u but clears u_valid. Resume continues at
  the next unconsumed sample, with no skipped RNG transitions.
- Reset leaves the lane unseeded. An all-zero seed is illegal: loading it replaces
  old state with zero, clears u, and inhibits valid output until a nonzero seed
  load. No automatic seed substitution, saturation, or lane error port is added.
  The future controller must reject zero seeds and set bad_cfg as specified.
- Thus u_valid is delayed accepted run, qualified by reset/load/nonzero state;
  it is not an unconditional delayed copy of raw run on exceptional edges.

## Verification and commands

`model/rng_lane.py` uses simultaneous next-state equations. The independent
`model/rng_canonical_reference.py` directly transcribes the canonical sequential
C assignments with ctypes.c_uint32 conversions, imports no production helper,
and validates output AND state. This is a Python transcription, not a compiled
execution of the original C. Tests compare all 128 one-hot seeds, all-ones and
random seeds for 256 steps, plus a 10,000-word stream. Directed tests exercise
packing, wraparound, controls, zero seeds, and reset recovery.

`model/gen_rng_vectors.py` emits deterministic per-edge vectors with seed 382,
directed cases plus 4096 randomized control cycles. Rows contain:
`rst_n seed_load run seed_state u_valid u state_after` (all hexadecimal).
The unit tests verify the checked-in artifact against both its generator and an
independent canonical/control scoreboard.

`tb/tb_rng_lane.sv` drives at falling edges and checks after rising-edge NBA
updates. It checks every cycle's valid, u (including held values), and internal
state; mismatches, missing/malformed/empty input, or timeout are fatal. A separate
check asserts reset between clock edges during an active stream while load/run
are high. The optional `+STREAM_FILE=...` writes valid vector-driven u words as
hex lines for future stream analysis; it excludes the reset preamble.

```bash
make rng-gen       # regenerate tb/vectors/rng_lane.hex
make rng-test      # Python RNG-only regression
make test          # all Python tests, including Gaussian regression
make rng-sim       # VCS compile/run (lab machines)
make rng-lint      # Verilator --lint-only
# Optional stream export (after rng-sim has built the executable):
./simv_rng +STREAM_FILE=reports/rng_stream.hex
```

Gaussian gen/sim/lint targets retain their existing inputs and defaults. RNG
simulation uses simv_rng and its own build directory. No tool install is assumed.

## Local validation results (2026-10-13)

- Python 3.13 / NumPy 2.3.3: `python -B -m unittest -v` from model/ passed
  all 17 tests (9 RNG, 8 existing Gaussian).
- Independent canonical output/state comparison passed 59,664 algorithm steps.
- All 4,440 generated vector cycles (1,763 valid words) passed the independent
  canonical/control scoreboard and artifact reproducibility check.
- Python AST checks and source whitespace checks passed; `git diff --check`
  passed. Existing Gaussian Make recipes were compared against HEAD and preserved.
- Make, VCS, Verilator, Icarus, GCC, and Clang were not found on PATH. Make targets,
  SystemVerilog simulation/lint, and compiled canonical C validation could not
  run here. No synthesis, timing closure, or RNG statistical battery is claimed.
- Changes remain local and uncommitted for review.

## Remaining milestones

- Run VCS and Verilator on a machine with those tools; synthesize to measure II,
  timing and area (one stage is a structural design, not a timing-closure claim).
- Add software jump-separated seeding and reproducible seed manifests for 2/4
  lanes; keep jump hardware outside the lane.
- Add stream statistics/export analysis, RNG-to-Gaussian integration, and mc_top
  bad_cfg checks. Algorithm equivalence is not a statistical-quality battery.
