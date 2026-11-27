# Physical validation of the RNG carry-select candidate

Tyler Haverlah, 2026-11-27. The RNG candidate passes routed setup and hold in
both tools at 1/2/4 lanes after a targeted two-lane hold ECO. Zero-limit
capacitance rows remain unresolved. This is not physical signoff.

## Scope and fixed inputs

Validate draft PR #27 at `9a0dda5c6346ad10e775de4711cade2d7e52f9a3`, based on
main `f137a6c`. Shentong owns the RNG RTL. This follow-up changes no RTL, library,
constraint or shared flow. Compare the new implementations with the archived
`tyler_closure2_20261123` results, which remain unchanged.

All runs use a10/k10, G1/M1, no retiming, a 5 ns period, the versioned
`setup_fixed_v1` library pair and the existing I/O and reset constraints.
The implementation policy is `HOLD_TARGET_SLACK_NS=0.08`,
`PRESERVE_SYNTH_BUFFERS=1`, `CTS_MAX_FANOUT=16`, `FIX_FANOUT_LOAD=1` and
`SETUP_TARGET_SLACK_NS` unset. Zero-valued capacitance limits remain unresolved;
no library change or course-staff question is proposed.

## Completed review and functional checks

- Reviewed the 32-bit current-state sum invariant and the four-byte carry-select
  arithmetic. Reset, seed load, accepted run and pause preserve the invariant.
  The registered output retains its canonical one-cycle latency.
- Audited all 132 archived source-manifest entries for each of main, prototype 1
  and prototype 2 against their Git sources. Exact hashes either match directly
  or match a reconstruction using only LF/CRLF conversion. The constraint,
  synthesis scripts and paired libraries are byte-identical across the versions.
- Checked the fresh standalone synthesis evidence: main +0.00604582 ns,
  candidate +0.597332 ns; gain +0.59128618 ns. RNG cell area rises from
  5,274.931992 to 6,335.080712 um2, with 193 registers. This clears the approximate
  +0.3 ns screen, without establishing routed closure or electrical acceptance.
- Independently reran the library check, 109 model tests and 67 flow tests on
  mario. All pass with no skips.
- Independently reran the RNG regression: 4,193 modular-adder checks, 4,440
  cycles and 1,763 valid outputs, including reset/load/pause and sum invariants.
- Independently reran the 24 real-array RTL configurations, two reduction-tree
  tests and the k8 detailed trace test. All 27 configurations pass.
  Shentong's three million-word canonical stream checks remain supporting
  evidence; those long captures were not repeated in this follow-up.

## Physical acceptance

For each lane count, inspect setup and hold in both PrimeTime and Innovus,
fanout, transition, reset and positive-limit capacitance violations, geometry,
connectivity, RC annotation, coverage and mapped/routed replays. Report every
zero-limit row separately. Successful tool execution is not acceptance.

The final [run matrix](../reports/multilane_rng_lookahead_runs.csv) and
[generated table](../results/multilane_rng_lookahead.md) pass the existing
digest/corpus/library/SDC/RC/activity collector and the additional
[acceptance check](../reports/lab_artifacts/tyler_rngphysical_20261127/review_acceptance.py).
Its [JSON record](../reports/rng_physical_acceptance_20261127.json) retains coverage
and every zero-limit capacitance row.

| Lanes | PT setup / hold (ns) | Innovus setup / hold (ns) | Hold ECO buffers | Zero-limit capacitance rows |
|---:|---:|---:|---:|---:|
| 1 | +0.866142 / +0.014980 | +0.400 / +0.069 | 0 | 4,564 |
| 2 | +0.695692 / +0.014762 | +0.182 / +0.005 | 1 | 8,280 |
| 4 | +0.541805 / +0.012737 | +0.146 / +0.018 | 0 | 15,732 |

Mapped and final routed replays each pass 81 cases / 82,489 trials across the
matrix. All three layouts pass geometry and connectivity. PT reports no setup,
hold, fanout, transition, reset or positive-limit capacitance violations;
Innovus reports no setup, hold, fanout or transition violations. In the one-lane
run the worst setup endpoint moves to the pricing multiplier's `acc_r` register.
The two-lane Innovus hold margin is only 5 ps and remains a material limitation.

## The initial matrix and targeted hold repair

The unchanged shared flow first completed all three candidate layouts. Its
[initial matrix](../reports/multilane_rng_lookahead_initial_runs.csv) and
[initial results](../results/multilane_rng_lookahead_initial.md) are preserved:
one and four lanes passed both tools, but two-lane Innovus hold failed by 20 ps
despite passing PT. That initial matrix is not the accepted result.

The failing path was `u_lanes/u_price/u_exp/s_t_reg_20_/Q` to
`u_lanes/u_price/p_reg_20_/D`, through an inverter, full adder and OAI gate.
Starting from the clean saved two-lane database, a local ECO inserted one
`BUFX2` before the endpoint. The functional netlist diff adds one wire and buffer
and reconnects that D pin. The SDC is identical apart from its timestamp comment;
the clock, I/O, reset and electrical constraints are unchanged.

The first ECO, tag `tyler_rng_closure_20261127_l2_hold1`, passed timing and replay
but introduced two filler overlaps, two associated shorts and four connectivity
diagnostics. It is rejected and retained as a negative control. Running the
acceptance checker with
[its manifest](../reports/multilane_rng_lookahead_rejected_eco_runs.csv) exits 1
specifically for geometry and connectivity, as recorded in
[the rejection JSON](../reports/rng_physical_negative_control_20261127.json).

The accepted retry, `tyler_rng_closure_20261127_l2_hold2`, starts again from the
original clean database. It removes only cells with master `FILL`, inserts the
same functional buffer, routes the ECO and rebuilds fillers. Geometry and
connectivity then pass. Its
[script](../reports/lab_artifacts/tyler_rngphysical_20261127/targeted_hold_eco_refill.tcl)
and [runner](../reports/lab_artifacts/tyler_rngphysical_20261127/run_hold_eco.sh)
are archived with parent-output/database hashes. Parent database hashes re-verify.
The shared implementation flow is unchanged; the two-lane final matrix explicitly
includes this additional physical repair. A shared-flow-only rerun reproduces the
initial matrix and still needs the recorded ECO.

## Cost against the archived closure2 reference

| Lanes | DC area (um2) / change | Routed signal-cell area (um2) / change | Estimated power (mW) | Energy (pJ/trial) |
|---:|---:|---:|---:|---:|
| 1 | 34,342.9 / +4.0% | 34,296.9 / +2.2% | 10.8 | 54.6 |
| 2 | 60,361.8 / +4.5% | 60,195.2 / +2.2% | 19.3 | 49.5 |
| 4 | 111,797.6 / +4.5% | 111,309.0 / -1.1% | 36.1 | 47.6 |

Changes are relative to [closure2's CSV](../results/multilane_closure_v1.csv),
using the same definition for each metric. The standalone RNG's 20.1% area
increase becomes about 4 to 5% in full-top synthesis. Physical optimization
changes the buffer/placement solution, so routed area does not scale directly
with mapped area. The four-lane routed result is smaller; this is one matched
implementation outcome, not a guaranteed area or power reduction.

The same 60% initial-utilization policy creates new floorplans because the mapped
netlists have changed. Core and die areas are not held to the old absolute values.
DC uses Liberty areas; routed signal-cell area uses LEF geometry and excludes
fillers. Power uses one zero-delay 1,000-trial workload and three-significant-digit
reports. Small power differences have limited precision.

Latency and busy cycles remain unchanged: 1,011 / 512 / 263 cycles for 1,000 trials,
or 197.8 / 390.6 / 760.5 million trials per second at the evaluated 5 ns target.
These rates are calculated from simulation cycles and the target period, not
measured silicon throughput or a rated maximum frequency. Bit-exact RNG behavior
and the unchanged numerical datapath allow reuse of the existing accuracy study.

## Limits retained for the report

- Zero-limit max-capacitance rows remain 4,564 / 8,280 / 15,732. No positive-limit
  violation is reported. The six-decimal PT reports can distinguish zero from
  this library's smallest positive limit, 0.0700296 pF. No limit is waived or
  changed.
- PT leaves 4,730 / 7,514 / 13,094 of 10,352 / 16,552 / 28,976 checks untested,
  mainly asynchronous recovery/removal and minimum pulse width. Covered checks
  have zero violations; coverage is not complete.
- Timing remains a one-typical-corner estimate using native RC and the documented
  setup-table approximation. Off-grid library evaluation and inter-tool
  disagreement remain. The minimum Innovus hold margin is 5 ps.
- DC constraint reports retain capacitance and max-leakage-power costs. Those
  costs are not the activity-based PT power measurements above.
- No multi-corner/PVT signoff, characterized RC, foundry DRC/LVS, IR/EM or
  SDF-annotated replay was added. The replays are zero-delay. Full electrical
  signoff and a rated maximum frequency are not established.

## Report figures and traces

- [PPA/throughput figure](../results/multilane_rng_lookahead.png), with editable
  SVG and PDF beside it. Its area panel is DC area; use the table above for the
  routed-area comparison.
- Native routed layout exports:
  [one lane](figures/rng_lookahead_l1.png),
  [two lanes after ECO](figures/rng_lookahead_l2.png),
  [four lanes](figures/rng_lookahead_l4.png).
  Each viewport is fitted independently; compare areas using the measured table.
- Critical paths: each final PT folder's `setup.rpt` and `hold.rpt`, and each
  final PNR folder's `postroute/mc_top_all.tarpt.gz` and
  `postroute_hold/mc_top_all_hold.tarpt.gz`. Exact folder names are in the matrix.

## Reproduction

Validation branch: `tyler/rng-physical-validation`. The lab worktree is
`mario:/home/work/teh969/mc_rngphysical_20261127`, under Tyler's account.
The library and Python environment are the existing project setup.

One lane was completed and reviewed before running two and four lanes serially.
The initial runners and stage logs are under `build/tyler_rng_20261127/` on the
lab. Exact commands, source audit and retention are documented in the
[artifact record](../reports/lab_artifacts/tyler_rngphysical_20261127/README.md).
All runs use Innovus 21.18-s099_1, DC T-2022.03-SP2, PT T-2022.03-SP5 and VCS
T-2022.06. Existing lab Python is 3.12.16 with NumPy 2.5.4 and matplotlib 3.11.2.

Use fresh tags and preserve the earlier baselines. Review and merge the RNG
candidate and its physical evidence before presenting these as the integrated
main result.
