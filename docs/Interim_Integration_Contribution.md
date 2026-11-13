# Interim report contribution: integration and tool flow

Tyler Haverlah, 2026-11-11. Source baseline: merged main `a83501c`.
Prepared for Shentong's [shared report draft](https://docs.google.com/document/d/1isvrOuPwzOCb3ohCs8GTmFbX7jLQcdSlMBD0RpaKZDk/edit).
The text below is a contribution to that draft; proposed dates need team agreement.

## III. Current progress: integration and implementation evidence

We have integrated a complete one-lane accelerator. A configuration bus programs
the option coefficients, trial count and RNG seed; a controller loads the lane,
issues the requested trials, drains the pipeline and returns the payoff sum,
completed count and sticky status flags. The datapath connects the xoshiro RNG,
Gaussian lookup, fixed-point stock-price/payoff pipeline and accumulator. Defaults
use a 16-bit Q3.12 Gaussian sample and an 18-bit Q5.12 exponential input.

The integrated RTL has passed 88 cases across four latency configurations,
comparing 105,828 trials with the Python reference. These checks cover every
qualified stage value, final results, saturation flags, reset/restart and
sustained II=1. The interim integration branch passes 85 model tests and 21 flow tests. On
November 11, a freshly synthesized one-lane netlist also passed an independent
interface-only replay of 22 cases and 26,457 trials. This confirms preservation of
results, status, reset/restart and busy-cycle counts through synthesis. It is a
zero-delay cell simulation, without SDF timing annotation or a formal equivalence
proof.

Fresh synthesis at the 5 ns target gives 33,016.19 um² and 913 registers. DC
reports +0.000510 ns setup slack, but independent PrimeTime reports **−0.200381 ns
setup slack** and **−0.041280 ns hold slack** on the mapped netlist. The flow also
reports 4,471 capacitance violations; PrimeTime coverage contains untested checks
and warns about 755 asynchronous set pins without clocks. We preserve these
diagnostics and will review their causes before timing signoff. There is no routed
layout yet. The 4.7455 mW synthesis power is an unannotated estimate, so energy per
trial is not established.

### Gaussian address-width rationale added to the shared report, 2026-11-13

The Gaussian address is the upper 10 bits of the 32-bit RNG word, `u[31:22]`:
1,024 equal-probability midpoint bins, with symmetry storing 512 positive 16-bit
magnitudes (8,192 bits). The lower 22 bits do not affect the baseline lookup.

The matched 16-bit-output / LATENCY=1 area and full-chain pricing sweeps support
this baseline on the five-case grid:

| Address bits | Worst absolute full-chain bias vs Black-Scholes | Standalone Gaussian cell area (um²) |
|---:|---:|---:|
| 8 | 1.178314345% | 1,617.677062 |
| 10 | 0.381450507% | 4,059.914197 |
| 12 | 0.141929688% | 8,151.740816 |

Thus 8 bits misses the 1% criterion, while 12 bits improves accuracy at roughly
twice the area of 10 bits. This is a measured baseline tradeoff, not a claim of
global optimality or standalone timing signoff. Sources: `results/d5_x_width.csv`
at Q5.12 (18-bit x) and `results/gauss_lut_ppa.csv` at 16-bit Gaussian output.
These full-chain bias values differ from the Gaussian-only float-exp bias table.

The November 13 bounded check reproduced all 15 relevant pricing rows and compared
all 1,024 addresses with quantized normal midpoint values. It confirmed the 512-word
half-ROM and lower-bit invariance. The existing 11,029-vector corpus covers all
1,024 address prefixes and agrees with the model; the archived baseline VCS runs
passed those vectors at LATENCY=1 and 2 (`reports/vcs_regression_2026-10-31.txt`).
No fresh VCS run or RTL change is claimed for this report addition.

## IV. Team responsibilities

| Member | Contributions to date | Remaining responsibility |
|---|---|---|
| Tyler Haverlah | Top/controller/configuration interface; shared synthesis-flow reconciliation and constraints; full-lane regression; mapped simulation and independent STA; verification-runner corrections | Resolve timing/coverage/electrical issues; integrate real 2/4-lane hardware; coordinate fair PPA comparisons; take a representative design through layout |
| Chuanqi Chen | Gaussian LUT and fixed-point model; shared constants/rounding; integrated golden model; accuracy and x-width studies; Gaussian synthesis sweep and figures | Review remaining numerical tradeoffs and interfaces; support interpretation of accuracy versus hardware cost |
| Eric Goode | Stock-price, exponential, payoff and accumulation RTL/models; datapath verification | Support datapath timing/width decisions and multi-lane reduction/accumulation integration |
| Shentong Zhong | RNG RTL/model; canonical stream checks and quality screening; archived VCS/synthesis evidence; interim draft assembly | Review jumped seed policy for multiple lanes and validate real multi-lane streams |

## V. Remaining work and proposed schedule

These are proposed completion targets, not completed work or agreed commitments.
The final presentation/report dates below come from the versioned project brief;
the team should confirm the assigned presentation slot and current Canvas dates.

| Target | Task and exit evidence | Proposed lead |
|---|---|---|
| Nov 12 | Incorporate reviewed contributions into the interim report; agree configuration concurrency and remaining scope | Team; Shentong assembles |
| Nov 13 | Reconcile DC/PrimeTime endpoint setup-time difference; classify untested/constant/reset checks and leakage-constraint diagnostic | Tyler with Eric |
| Nov 16 | Establish the implementation constraints and electrical/hold repair plan; prepare the one-lane P&R flow | Tyler |
| Nov 20 | Real 2/4-lane RTL, registered reduction and jumped per-lane seeds; exact sums/counts and partial final beats in simulation | Tyler with Eric/Shentong; Chuanqi reviews numerical choices |
| Nov 24 | First representative routed one-lane implementation; inspect extracted setup/hold and physical verification | Tyler |
| Nov 27 | Comparable 1/2/4-lane synthesis results; routed baseline timing, activity-based power and remaining physical fixes | Tyler and block owners |
| Nov 30 | Freeze comparison tables and presentation material; retain a verified one-lane fallback | Team |
| Dec 1/3; Dec 9 | Course presentation slot; final report and reproducible source/results package | Team |

Main risks are the unresolved timing-engine discrepancy, very small DC setup
margin, hold/capacitance cleanup, and unfinished real multi-lane hardware. If
scaling or physical closure slips, retain the verified one-lane implementation and
report the outstanding limits explicitly. Compare all lane counts under the same
pre-layout flow; present routed-baseline results separately rather than mixing
physical and synthesis estimates in one scaling table.

## VI. Response to the professor's proposal feedback

**Accuracy criteria.** We now separate deterministic approximation bias from
Monte Carlo sampling noise. The criterion is absolute relative deterministic bias
at most 1% on five representative call-pricing scenarios. The baseline exact
hardware expectation differs from Black-Scholes by at most 0.3815% on this grid.
The 100-seed study reports single-run sampling spread and 93–94% observed coverage
for nominal 95% intervals around the hardware expectation. This coverage uses
software per-trial variance; the RTL currently returns sum/count and flags, not a
squared-payoff sum. It does not establish a universal 1% total-error guarantee.
The width study supports retaining 18-bit Q5.12 as the baseline.

**Confidence in throughput.** The per-lane target of one completed trial per
cycle after fill is verified in integrated RTL. The mapped simulation confirms
default run duration `N + 11` busy cycles. At N=10,000 this is 10,011 cycles, or
99.89% of the ideal one-trial/cycle rate. A 5 ns clock would imply 199.78 million
trials/s for that batch, excluding configuration and reset release. This is a
conditional projection: independent STA currently misses the 5 ns setup target.
Frequency closure, real 2/4-lane scaling and activity-based energy remain measured
evaluation tasks before final claims.

## Figures and evidence for the editor

- Architecture: `docs/figures/lane_block_diagram.png`.
- Accuracy: `docs/figures/price_vs_bs.png`; numerical data in `results/price_vs_bs.csv`.
- Datapath II=1 waveform: `docs/figures/wave_price_dp.png`.
- New batch-efficiency figure: `results/one_lane_interim_throughput.png` and CSV.
  Caption: "Mapped zero-delay replay confirms N+11 busy cycles for the default
  one-lane design. Target-frequency throughput is conditional on timing closure."
- Existing four-configuration RTL evidence:
  `reports/sim/rng_validation_sim-top/g{1,2}_m{1,2}/run.log.txt` (November 8).
- Fresh mapped functional evidence: `reports/sim/gate_interim_20261111/`.
- Fresh DC results: `results/one_lane_interim_5ns.csv` and `reports/syn/mc_top_interim_20261111/`.
- Independent STA: `results/one_lane_interim_sta.csv` and `reports/sta/mc_top_interim_20261111_clean/`.
- Validation/provenance: `reports/interim_validation_2026-11-11.txt` and source manifest.

This contribution does not replace the report's required 3–5-source literature
review. Reuse the team's checked references and connect each source to a design
choice; the older broad research plan includes features outside the current scope.

## Shared draft review, 2026-11-12

Shentong invited direct corrections to the shared draft. Tyler reviewed and edited
the integration, synthesis and feedback sections against the committed evidence.
The draft now distinguishes deterministic bias from software CI coverage, states
that 199.78 Mtrials/s is conditional on an unclosed 5 ns clock, and separates common
pre-layout lane comparisons from the later routed baseline. The large module
screenshot was replaced by a native text excerpt of the default lane connections.
The native equations, architecture/waveform figures and responsibilities table are
preserved. The table heading/header now stays with its rows.

The edited Google Doc was read back and exported for visual QA: seven equations,
one responsibilities table and seven rendered pages were verified. Temporary PDF
exports and review PNGs are disposable; the shared Doc is the report source.
Shentong's November 17/24/30 schedule was retained. No Slack message was sent.
