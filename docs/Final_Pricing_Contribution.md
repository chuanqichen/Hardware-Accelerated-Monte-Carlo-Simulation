# Final report contribution: pricing datapath and accumulator

Eric Goode, 2026-11-22. Text for the team's final report, in the same form as
`Interim_Integration_Contribution.md`. Every number comes from a file under `results/`
or `reports/`; the last section lists them for the editor. The design rationale behind
this summary is `Pricing_Datapath_Work_Plan.md`.

## What the block does

Each lane turns one Gaussian sample $z$ into one option payoff per clock cycle, and the
accumulator adds the payoffs up:

$$
x = A + Bz, \qquad S_T = e^{x}, \qquad p = \max(S_T - K,\,0), \qquad
\texttt{payoff\_sum} = \sum p .
$$

The host folds the five option parameters into the constants $A$, $B$ and $K$ before a
run and divides and discounts the sum afterwards, so the hardware needs no logarithm,
square root or divider.

## Design

**Six pipeline stages, one trial per cycle.** `price_dp` is a six-stage pipeline: a
fused multiply-add, a rounding stage, three stages for the exponential and one for the
payoff. A new trial enters every clock and a result leaves every clock, six cycles
later. A valid bit travels beside the data, so a result is never paired with the wrong
cycle.

**Fused multiply-add.** $A$ is added inside the multiplier's compression tree as one
more row, so $A + Bz$ costs one carry-propagate adder, not two. The sum is rounded once,
half to even, and saturated by the team's shared `round_sat` module.

**Exponential by range reduction.** $e^x$ is rewritten as $2^y$ with $y = x\log_2 e$.
The integer part of $y$ is a shift. Only the fractional part needs a table: $2^f$ for
$f \in [0,1)$, stored at cell midpoints. A direct table on $x$ at the same resolution
would need about 65,000 entries; this one needs $2^k$, with $k$ = 10 as the baseline.

**Accumulator.** A 64-bit sum, a 32-bit trial count and sticky flags for the two
saturation events. With more than one lane, a registered pairwise tree adds the lanes
first, one level per doubling of the lane count, so no cycle holds more than one small
adder or the 64-bit add. The count adds the number of valid lanes, which lets the
controller mask unused lanes on the last beat and finish with exactly the requested
number of trials.

## Verification

The Python model is bit-accurate and was written first; each RTL block is compared with
it value for value.

| Test | Coverage | Result |
|---|---|---|
| `tb_exp2_unit` | all 262,144 values of $x$, at $k$ = 8 and 10 | 0 errors |
| `tb_price_dp` | 11,449 directed and random trials: payoff, flags and exact latency, at $k$ = 8 / 10 and one or two multiplier stages | 0 errors |
| `tb_price_dp`, continuous | 8,192 trials with valid high on every cycle; requires 8,192 consecutive valid results | 0 errors |
| `tb_accumulator` | 1, 2 and 4 lanes, 64- and 32-bit sums; random lane masks and clears; runs of 101, 1,001 and 10,003 trials with a masked last beat | 0 errors |
| Multi-lane array | 24 configurations of 1, 2 and 4 real lanes against the model: sum, count, status | all pass |

All of these run under VCS in one command (`make sim-pricing-final`); the 2026-11-22 run
passed 50 of 50. The tests were themselves tested: deliberately broken copies of the RTL
(half-up rounding, an accumulator tree that does not empty on clear, a datapath that
fails only after 100 back-to-back results) each fail the test meant to catch them. The
exhaustive exponential test caught one real bug on its first run, a rounding constant
one bit too wide for its variable.

## Results

Design Compiler, FreePDK45 `gscl45nm` typical corner, 5 ns clock, the team's shared
constraints. These are pre-layout results for the blocks synthesized on their own.

| Block | Area | Registers |
|---|---:|---:|
| `price_dp`, $k$ = 10 | 13,777 um^2 | 151 |
| Accumulator, 1 lane | 3,123 um^2 | 99 |
| Accumulator, 2 lanes | 3,700 um^2 | 126 |
| Accumulator, 4 lanes | 5,123 um^2 | 182 |

`price_dp` is about 42% of the 33,016 um^2 one-lane design.

**Timing.** Both blocks meet setup timing at 5.00, 4.75 and 4.00 ns in synthesis; at
4.00 ns `price_dp` is 2.8% larger than at 5.00 ns. One multiplier stage is enough: a
second stage and register retiming each changed area and slack by a few percent at
most, so neither is used. The critical path is the fused multiply-add. These block
results do not show that the lane runs at 200 MHz: the team's PrimeTime analysis of the
one-lane design reports negative setup slack, and nothing here is routed.

**Lane scaling.** One `price_dp` per lane plus one shared accumulator gives 16,900,
31,254 and 60,230 um^2 for 1, 2 and 4 lanes: 1.85 and 3.56 times the one-lane figure.
These are sums of the block results above, not a synthesized multi-lane design.

## Numerical tradeoff: the exponential table

The price the hardware converges to can be computed exactly, with no Monte Carlo noise,
because the Gaussian table has finitely many outputs. Worst bias against Black-Scholes
over the five benchmark options:

| Gaussian table address bits | $k$ = 8 | $k$ = 10 | $k$ = 12 |
|---|---:|---:|---:|
| 8 | 1.17% | 1.18% | 1.21% |
| 10 | 0.36% | 0.38% | 0.38% |
| 12 | 0.15% | 0.14% | 0.14% |
| `price_dp` area | 10,035 um^2 | 13,777 um^2 | 23,942 um^2 |

The exponential table does not set the accuracy. Each extra address bit halves the
error of $e^x$ itself, but the option price moves by about 0.03 percentage points at
most between $k$ = 8 and $k$ = 12, while the Gaussian table moves it from 1.2% to 0.14%. The
datapath's own contribution to the bias, measured against the same Gaussian table with
exact arithmetic, is at most 0.05% and comes from rounding $A$, $B$ and $K$ to their
register formats.

A table of 256 entries ($k$ = 8) therefore gives the same accuracy as 1,024 for 27% less
`price_dp` area (3,742 um^2 per lane). The whole-lane synthesis agrees: 3,670 um^2, 11%
of the lane. We recommend $k$ = 8; the committed default is still 10.

A narrower Gaussian sample (12 bits, not 16) would save a further 722 um^2 in the
multiplier, 5% of `price_dp`.

## Limits

- Timing and area are pre-layout, for blocks synthesized alone. Throughput figures
  (200 million trials per second per lane at 5 ns) are conditional on the lane closing
  timing after layout.
- Power is the synthesis tool's estimate without switching activity; energy per trial
  is not established.
- Synthesis reports hold and maximum-capacitance violations for these blocks, as it
  does for the one-lane design. Hold is left to place and route.
- The reported flip-flop setup time is inflated by a known defect in the library's
  `DFFPOSX1` table, so the timing margins above are pessimistic.
- Clock gating of the stage enables was not measured.
- The bias numbers are for five benchmark options, not a guarantee over all inputs.

## Figures and evidence for the editor

- `docs/figures/pricing_exp_table_tradeoff.png`. Caption: "The exponential table size
  sets `price_dp` area, but price accuracy is set by the Gaussian table. Exact bias
  against Black-Scholes, worst of five benchmark options."
- `docs/figures/pricing_lane_scaling.png`. Caption: "Pricing area for 1, 2 and 4 lanes.
  Sum of standalone block syntheses at 5 ns, not a synthesized multi-lane design."
- `docs/figures/pricing_area_vs_clock.png`. Caption: "Area cost of a shorter clock period
  constraint, relative to 5 ns. All points met setup timing in pre-layout synthesis."
- `docs/figures/wave_price_dp.png`: datapath waveform, one result per clock.
- Area, timing: `results/price_dp_ppa.csv`, `results/accumulator_ppa.csv`,
  `results/price_dp_zwidth_ppa.csv`; raw reports under `reports/syn/u1*`, `u3*`, `v2*`.
- Accuracy against area: `results/pricing_accuracy_vs_area.csv`; lane rows:
  `results/pricing_ppa_configs.csv`; throughput: `results/pricing_throughput.csv`.
  Regenerate with `make pricing-study` and `make pricing-figures`.
- Verification record: `reports/pricing_final_validation_2026-11-22.txt` and
  `reports/sim/pricing_final_20261122*/summary.txt`.
- The bias values agree with `results/accuracy_vs_area.csv` and
  `results/exp_k8_candidate.csv`; use one set of numbers in the report.
