# Lane interface specification (DRAFT for team review)

_Status: proposal, 2026-10-03. Nothing here is frozen until the four owners sign off;
open points are collected in Section 9. Once agreed, this file is the contract that
`model/`, `rtl/`, and `tb/` are written against._

---

## 1. Purpose

One page that defines every signal between the blocks of a lane, the fixed-point
format on each one, the latency of each block, and how `valid` travels with the data.
Agreeing on this first is what makes the one-lane integration a wiring exercise
instead of a debugging exercise.

```
         ┌──────────── mc_top ──────────────────────────────────────────────────────────┐
 cfg bus │ ┌────────────┐                                                                │
 ───────►│ │ controller │─ run ─────┐                                                    │
 start   │ └─────┬──────┘           ▼                                                    │
 ───────►│       │           ┌──────────┐ u   ┌───────────┐ z   ┌───────────┐ p          │
         │       │           │ rng_lane │────►│ gauss_lut │────►│ price_dp  │─────┐      │
         │       │           └──────────┘ u_v └───────────┘ z_v └───────────┘ p_v │      │
         │       │                                                                ▼      │
 done    │       │                                               ┌──────────────────────┐│
 ◄───────│◄──────┴───────────────────────────────────────────────│ accumulator + counter││
 results │                                                       └──────────────────────┘│
         └───────────────────────────────────────────────────────────────────────────────┘
```

Blocks and owners: `rng_lane` (Shentong), `gauss_lut` (Chuanqi), `price_dp` = `A + B*z`
-> `exp` -> `max(S_T - K, 0)` and `accumulator` (Eric), `controller` + `mc_top` (Tyler).
Fixed-point formats and the rounding policy (Chuanqi) apply to all of them.

## 2. Global conventions

| Item | Rule |
|---|---|
| Clock | single `clk`; every block is fully synchronous to it |
| Reset | `rst_n`, active-low, asynchronous assert, synchronous de-assert (reset synchronizer in `mc_top`). All control state and `valid` bits reset; datapath registers may be left unreset |
| Handshake | **valid-only, no back-pressure.** Every stage accepts one item per cycle. `x_valid` is `in_valid` delayed by that block's latency. A stage must ignore its inputs when `valid=0` and must never assert its output `valid` for garbage |
| Throughput | one item per cycle per lane after fill (II = 1) |
| Latency | a compile-time `localparam LAT_<BLOCK>` in each block, exported through `mc_pkg`; the controller uses `LAT_TOTAL = LAT_RNG + LAT_GAUSS + LAT_DP` to size the drain |
| Fixed point | all formats below; one `round_sat` module for every narrowing; **round-half-to-even then saturate; no silent truncation**; saturation sets a sticky status flag |
| Naming | modules/files `snake_case`, parameters `UPPER_SNAKE`, `_n` active-low, `_valid` qualifiers, signed buses declared `logic signed` |
| Unknowns | no `x` on any `valid`-qualified bus after reset in simulation (assertion in `tb_mc_top`) |

## 3. Fixed-point formats (`Qi.f` = signed, `UQi.f` = unsigned; `i` excludes the sign bit)

| Symbol | Meaning | Format | Width | Range | Rationale |
|---|---|---|---:|---|---|
| `u` | uniform word | `uint32` | 32 | [0, 2^32) | RNG contract; high bits are the high-quality bits |
| `z` | standard normal | `Q3.12` | 16 | ±`Phi^-1(1 - 2^-(ADDR_BITS+1))` = ±3.30 at `ADDR_BITS=10` | fraction bits beyond 12 do not change price error |
| `A` | `ln S0 + (r - sigma^2/2) T` | `Q5.12` | 18 | ±32 | `ln(10 000) = 9.2`; room for negative drift |
| `B` | `sigma * sqrt(T)` | `UQ2.14` | 16 | [0, 4) | sigma up to ~1.5 at T = 5 y |
| `bz` | `B * z` full product | `Q5.26` | 32 | product of the above | internal to `price_dp`, never stored |
| `x` | `A + round_sat(bz)` | `Q5.12` | 18 | ±32 | `exp` input; actual range is `A ± B*3.30` |
| `S_T` | `exp(x)` | `UQ14.8` | 22 | [0, 16 384) step 1/256 | covers `S0 <= 2 000` at sigma = 0.6 with margin |
| `K` | strike | `UQ14.8` | 22 | same as `S_T` | compared/subtracted directly |
| `p` | payoff `max(S_T - K, 0)` | `UQ14.8` | 22 | same as `S_T` | no rounding: subtract and clamp |
| `payoff_sum` | `sum p` | `UQ46.8` | 54 -> stored in 64 | 2^32 trials x 2^14 | 64-bit result register; overflow flagged |
| `trial_count` | accepted trials | `uint32` | 32 | | |

Software side (Python, double precision): `A = ln(S0) + (r - 0.5*sigma**2)*T`,
`B = sigma*sqrt(T)`, then quantize with `Fxp(18,12)`, `Fxp(16,14,signed=False)`,
`Fxp(22,8,signed=False)`; price `= exp(-r*T) * payoff_sum / trial_count / 256`.

Alternative under discussion (D-3): compute `S_T = C * exp(B*z)` with
`C = S0*exp((r - sigma^2/2)T)` precomputed. Then the `exp` input is symmetric and
bounded by `|B*z| <= 4 * 3.30`, which shrinks the exp table but adds one multiply.

## 4. Top-level interface (`mc_top`)

A small write-only configuration bus plus parallel result outputs. This scales to
multiple lanes (per-lane seeds) without hundreds of ports and keeps the testbench
trivial.

| Signal | Dir | Width | Meaning |
|---|---|---:|---|
| `clk`, `rst_n` | in | 1 | see Section 2 |
| `cfg_we` | in | 1 | write strobe |
| `cfg_addr` | in | 8 | register address (map below) |
| `cfg_wdata` | in | 32 | write data |
| `start` | in | 1 | one-cycle pulse; ignored while `busy` |
| `busy` | out | 1 | high from `start` until `done` |
| `done` | out | 1 | one-cycle pulse when results are final (also sticky in `STATUS`) |
| `payoff_sum` | out | 64 | `UQ46.8`, valid after `done` |
| `trial_count` | out | 32 | accepted trials (= `N_TRIALS` unless aborted) |
| `cycle_count` | out | 32 | cycles from `start` to `done`, for throughput evidence |
| `status` | out | 8 | sticky flags: `[0]` done, `[1]` sat_x, `[2]` sat_S, `[3]` acc_overflow, `[4]` bad_cfg (e.g. zero seed, `N_TRIALS=0`) |

Register map (32-bit words; formats per Section 3, right-aligned, zero-extended):

| Addr | Name | Content |
|---:|---|---|
| `0x00` | `A` | `Q5.12` in bits [17:0] |
| `0x01` | `B` | `UQ2.14` in bits [15:0] |
| `0x02` | `K` | `UQ14.8` in bits [21:0] |
| `0x03` | `N_TRIALS` | `uint32`, total across all lanes |
| `0x10 + 4*i + w` | `SEED[i][w]` | state word `w` (0..3) of lane `i`'s xoshiro128 state |

Configuration is latched on `start`; writes while `busy` are ignored and set
`bad_cfg`. A run is a pure function of the register contents: same registers, same
`payoff_sum` and `cycle_count`, every time.

## 5. Inter-block interfaces

### 5.1 controller -> `rng_lane`

| Signal | Width | Meaning |
|---|---:|---|
| `seed_load` | 1 | one-cycle pulse; lane copies its four `SEED` words into state |
| `seed_state` | 128 | the four words, `{s3, s2, s1, s0}` |
| `run` | 1 | while high, emit one `u` per cycle; de-asserted by the controller after the last trial has been issued |

### 5.2 `rng_lane` -> `gauss_lut`

| Signal | Width | Format | Meaning |
|---|---:|---|---|
| `u` | 32 | `uint32` | one xoshiro128++ output word |
| `u_valid` | 1 | | `run` delayed by `LAT_RNG` |

Requirements: uniform over all 2^32 values; one word per cycle; the all-zero state is
illegal (controller flags `bad_cfg`). For multi-lane, lane `i` is seeded by software
with `jump^i` of the root state (Vitis convention), so no jump hardware is needed.
`xoshiro128++` is preferred over `+` because the LUT consumes only the top bits and
`++` has no weak bits.

### 5.3 `gauss_lut` -> `price_dp`

| Signal | Width | Format | Meaning |
|---|---:|---|---|
| `z` | 16 | `Q3.12` | `Phi^-1` of the cell midpoint addressed by `u[31 -: ADDR_BITS]` |
| `z_valid` | 1 | | `u_valid` delayed by `LAT_GAUSS` |

`|z|` is bounded by the table, which bounds `x` and sizes the `exp` domain.
Reference: `model/gauss_lut.py`; RTL `rtl/gauss_lut.sv` (`LAT_GAUSS = LATENCY`
parameter, 1 or 2).

### 5.4 `price_dp` -> accumulator

| Signal | Width | Format | Meaning |
|---|---:|---|---|
| `p` | 22 | `UQ14.8` | `max(S_T - K, 0)` |
| `p_valid` | 1 | | `z_valid` delayed by `LAT_DP` |
| `sat_x`, `sat_s` | 1 each | | pulses when `round_sat` saturated `x` or `exp` clamped its input/output; made sticky in `status` |

Inside `price_dp` (Eric's internal stages, listed so the Python model can trace them):
`bz = B*z` (`Q5.26`) -> `round_sat` -> `Q5.12`; `x = A + bz_r` with saturation;
`S_T = exp(x)` by table (range-reduce `x` into integer/fraction of `log2 e * x`, shift
+ fractional LUT, or direct table - Eric's choice, bounded by the `x` range);
`p = S_T > K ? S_T - K : 0`.

### 5.5 accumulator and counter

- `payoff_sum <= payoff_sum + p` when `p_valid`; 64-bit; carry-out sets `acc_overflow`.
- `trial_count <= trial_count + 1` when `p_valid` (multi-lane: `+ popcount(p_valid[LANES-1:0])`).
- Both cleared on `start`.
- Multi-lane: a registered adder tree sums the `LANES` payoffs first; it adds
  `LAT_TREE = ceil(log2 LANES)` cycles and is part of `LAT_TOTAL`.

### 5.6 Controller sequence

```
IDLE  --start--> LOAD  (latch cfg, seed_load, clear sum/count/cycles)
LOAD  ---------> ISSUE (run=1; issued++ each cycle; run=0 when issued == N_TRIALS)
ISSUE ---------> DRAIN (wait until trial_count == N_TRIALS, or LAT_TOTAL cycles as a bound)
DRAIN ---------> DONE  (done pulse, status[0]=1, busy=0) --> IDLE
```

`cycle_count` counts from `start` to `done` inclusive. For `LANES > 1` the controller
issues `ceil(N_TRIALS / LANES)` beats and masks the unused lanes in the final beat so
`trial_count == N_TRIALS` exactly.

## 6. Latency budget (initial estimates - replace with measured values)

| Block | `LAT_*` | Notes |
|---|---:|---|
| `rng_lane` | 1 | state update + output register |
| `gauss_lut` | 1-2 | ROM + negate; 2 if timing needs it |
| `price_dp` | 4-6 | multiply (1-2), add/round (1), exp (2), payoff (1) |
| adder tree (`LANES=4`) | 2 | |
| accumulator | 1 | |
| **one-lane total** | **7-10** | pipeline fill before first `p_valid`; drain equal |

Throughput goal: `N_TRIALS + LAT_TOTAL + ~3` cycles per run for one lane.

## 7. Python reference contract (`model/mc_lane.py`, to be written)

```python
def run_lane(a_raw, b_raw, k_raw, seed_state, n_trials, cfg) -> dict
    # returns {"payoff_sum": int, "trial_count": int, "sat_x": int, "sat_s": int}
def trace_lane(...) -> list[dict]   # per trial: u, z, bz, x, S_T, p (raw ints)
```

Every block owner provides a pure function `block(raw_in) -> raw_out` using
`model/fxp.py`; `run_lane` chains them. `trace_lane` is what you diff against the
waveform when the integrated testbench reports a mismatch.

## 8. Verification hooks every block must provide

| Block | Debug/observability requirement |
|---|---|
| `rng_lane` | raw `u` stream exportable from simulation (for Shentong's stream tests) |
| `gauss_lut` | assertion: half-table magnitude never sets the sign bit; exhaustive-address vectors |
| `price_dp` | `sat_x`/`sat_s` pulses visible; directed vectors for `x` at the exp-table edges |
| accumulator | overflow assertion; test with `p = max` for 2^20 trials |
| `mc_top` | `tb_mc_top` compares `payoff_sum`, `trial_count`, `status` with `run_lane`; checks `cycle_count` against the latency budget; asserts no `x` on valid-qualified buses |

## 9. Open decisions

| ID | Question | Options | Proposed | Owner |
|---|---|---|---|---|
| D-1 | Seed delivery for multiple lanes | (a) software writes 128 b per lane via cfg bus; (b) hardware jump from one root | (a) - no jump hardware, matches Vitis | Shentong, Tyler |
| D-2 | Reset style | async-assert/sync-deassert vs fully synchronous | async-assert (as in `gauss_lut.sv`) | Tyler |
| D-3 | `S_T = exp(A + B z)` vs `C * exp(B z)` | see Section 3 | decide after Eric sizes the exp table for both | Eric, Chuanqi |
| D-4 | `z` width | `Q3.12` (16 b) vs `Q3.8` (12 b) | start 16 b; 12 b if synthesis shows the multiplier matters | Chuanqi, Eric |
| D-5 | `A`/`x` width | 18 b `Q5.12` vs 16 b `Q5.10` | 18 b; revisit after exp-table precision study | Eric, Chuanqi |
| D-6 | `exp` implementation | direct table on `x` vs range reduction + fractional table | Eric to propose with table-size numbers | Eric |
| D-7 | Top-level bus | cfg write bus (Section 4) vs all-parallel ports | cfg bus | Tyler |
| D-8 | `N_TRIALS` not a multiple of `LANES` | lane mask on last beat vs require multiple | lane mask | Tyler |

Decisions get recorded here with the date; the Python model, RTL, and vectors are then
regenerated from the agreed values rather than patched by hand.
