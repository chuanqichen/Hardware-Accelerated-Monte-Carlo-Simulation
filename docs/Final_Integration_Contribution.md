# Final report contribution: integration, verification and physical flow

Tyler Haverlah, 2026-11-24. Text for the team's final report, in the same form as
`Final_Pricing_Contribution.md`. Source: merged `main` `5cda1dd`. Every number comes
from a committed file under `results/` or `reports/`; the last section lists them for
the editor. Evidence from PR #24 is linked to its reviewed commit `0fa27ec`.

## What I contributed

**Integration.**

- **One-lane accelerator (PR #7).** A configuration bus and controller around the
  RNG, Gaussian lookup, pricing datapath and accumulator, built on one shared 5 ns
  synthesis flow with fresh run tags and source and library hashes. VCS compared
  88 cases and 105,828 trials with the Python model across the four
  Gaussian-latency and multiplier-stage settings. Traces and results matched
  exactly, with sustained one-trial-per-cycle throughput.
- **Real 1/2/4-lane hardware (PR #17).** Replicated lanes, a registered reduction
  tree, jump-separated seeds and masked partial final beats. At merge, all 35 VCS
  replay configurations passed. They include 24 real-array configurations: 1/2/4
  lanes, Gaussian latency 1/2, multiplier stages 1/2, and exponential tables k10
  and k8.

**Verification.**

- **First independent checks after synthesis (PR #11).** A mapped-netlist replay
  passed 22 cases and 26,457 trials. Independent PrimeTime then found -0.200 ns
  setup and -0.041 ns hold slack, where Design Compiler reported +0.0005 ns. Chuanqi
  later isolated a `DFFPOSX1` setup-table anomaly and versioned a project-specific
  library correction (PRs #12 and #22).
- **Fail-closed tooling.** Regression runners that fail closed (PRs #6, #15), k8
  accuracy evidence (PR #16) and waveform and accuracy-plot fixes (PR #9).
- **Review and reproduction.** Reviews of PRs #21 and #22, and an exact
  reproduction of the #22 one-lane result on the lab host: PT setup +0.687440 ns,
  hold -0.025964 ns, 9.968 mW, and a routed replay of 26 cases and 27,492 trials.
- **Replays.** Both matched 1/2/4-lane implementations below pass mapped and
  routed replays of 81 cases and 82,489 trials.
- **Final checks (PR #24).** 109 model tests and 67 flow tests pass on the
  lab host with no skips. The three canonical result tables regenerate byte for
  byte, and the replay inputs reproduce exactly.

**Physical flow and closure (PR #23).**

- Root causes of the #22 baseline's open checks.
- An opt-in Innovus policy that clears every PT hold and max-fanout row at 1, 2
  and 4 lanes, without changing a constraint, RTL file or library value.
- A violation classifier, an SI-sensitivity diagnostic and an unsuccessful
  setup-target trial.
- In PR #24: a same-path PT/Innovus comparison, an RNG path note for the RNG
  owner and a manifest of the trial's lab-only files.

## Results

Every run below uses the same conditions:

- FreePDK45 `gscl45nm` with the versioned `setup_fixed_v1` library pair, the
  typical 1.1 V / 27 C corner and a 5 ns clock.
- a10/k10, G1/M1 and no retiming.
- Native RC estimates without a characterized capacitance table.
- Power from zero-delay gate-level activity over one 1,000-trial workload.
- Innovus v21.18-s099_1 places, routes and times each layout with SI-aware delay
  calculation. PrimeTime T-2022.03-SP5 independently times the same routed netlist
  and parasitics.

Both comparisons use these area definitions:

- **DC area:** synthesized cell area. Both implementations place the same
  `setupfix_v1_20261123` netlists, so it is identical.
- **Routed signal-cell area:** Innovus standard-cell area excluding physical cells
  such as fillers ("Total area of Standard cells (Subtracting Physical Cells)").
- **Core and die area:** the floorplan, also identical.

### PR #22 corrected-library baseline

Chuanqi's matched implementation (`setupfix_v1_20261123`) with the default Innovus flow:

| Lanes | PT setup / hold (ns) | Innovus setup / hold (ns) | Both tools pass setup/hold | PT hold rows | PT max-fanout rows | Zero-limit max-cap rows |
|---:|---:|---:|:---:|---:|---:|---:|
| 1 | +0.687 / -0.026 | +0.082 / +0.001 | No | 33 | 160 | 4,607 |
| 2 | +0.539 / -0.028 | +0.030 / 0.000 | No | 98 | 255 | 8,350 |
| 4 | +0.569 / -0.026 | -0.019 / -0.022 | No | 186 | 483 | 16,124 |

### `tyler_closure2` reference

The netlists, constraints, library and floorplan are unchanged. The opt-in policy
does four things:

- sets an Innovus hold target of 0.08 ns
- keeps DC's buffer trees
- limits clock-tree fanout to 16
- requests fanout repair

| Lanes | PT setup / hold (ns) | Innovus setup / hold (ns) | Both tools pass setup/hold | PT hold rows | PT max-fanout rows | Zero-limit max-cap rows |
|---:|---:|---:|:---:|---:|---:|---:|
| 1 | +0.355 / +0.021 | +0.058 / +0.080 | Yes | 0 | 0 | 4,491 |
| 2 | +0.283 / +0.018 | +0.002 / +0.033 | Yes | 0 | 0 | 8,139 |
| 4 | +0.260 / +0.033 | **-0.006** / +0.006 | No | 0 | 0 | 15,596 |

The four-lane failure is one Innovus setup path in lane 3's RNG, `s0_reg_5_` to
`u_reg_31_`. The next path has +0.051 ns. In both implementations, geometry and
connectivity checks are clean, and PT finds no negative reset recovery or removal
slack.

### Area and power cost

| Lanes | DC area (um^2) | Routed signal-cell area, #22 to closure2 (um^2) | Change | Innovus hold cells, #22 to closure2 | Power, #22 to closure2 (mW) | Change | Energy, #22 to closure2 (pJ/trial) |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 33,033.6 | 29,817.9 to 33,571.8 | +12.6% | 24 to 499 | 9.968 to 10.8 | +8% | 50.4 to 54.6 |
| 2 | 57,736.1 | 53,033.7 to 58,925.3 | +11.1% | 44 to 932 | 17.8 to 19.2 | +8% | 45.6 to 49.2 |
| 4 | 106,959.1 | 99,424.5 to 112,537.2 | +13.2% | 132 to 2,865 | 33.1 to 36.8 | +11% | 43.7 to 48.6 |

- **Floorplan.** Core area is 52,415.2 / 91,550.1 / 169,518.7 um^2 and die area is
  72,481.9 / 117,548.0 / 204,310.1 um^2 in both implementations.
- **Where the area goes.** The baseline placement deleted DC's buffer trees.
  The policy keeps those trees, and Innovus adds the hold cells. DC uses Liberty
  cell areas while Innovus uses LEF geometry, so the absolute DC-to-routed area
  difference cannot be attributed entirely to buffer deletion. The policy's cost
  above compares routed signal-cell area using the same definition in both runs.
- **Power precision.** PT reports power to three significant digits, so the power
  changes are rounded to whole percent.
- **Cycle count.** It is unchanged. One workload completes 1,000 trials in
  1,011 / 512 / 263 busy cycles: 197.8 / 390.6 / 760.5 million trials per second at
  5 ns, conditional on timing closure.

### Setup-target trial (unsuccessful)

`tyler_closure3_20261124` repeated the reference policy with an Innovus setup target
of 0.05 ns. Nothing else changed.

| Lanes | PT setup / hold (ns) | Innovus setup / hold (ns) | Innovus hold cells | Routed signal-cell area (um^2) | Power (mW) | Energy (pJ/trial) |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | +0.244 / +0.028 | +0.006 / +0.075 | 449 | 33,229.3 | 10.5 | 53.1 |
| 2 | +0.304 / +0.012 | **-0.010** / +0.024 | 1,013 | 59,175.9 | 19.2 | 49.2 |
| 4 | +0.329 / +0.015 | +0.028 / **-0.023** | 2,228 | 110,492.5 | 36.1 | 47.6 |

- **Outcome.** The trial fixed four-lane setup but failed two-lane setup and
  four-lane hold in Innovus, while PT passed every setup and hold check. Its
  zero-limit max-capacitance rows are 4,492 / 8,141 / 15,599. `tyler_closure2`
  remains the reference.
- **SI sensitivity.** Both four-lane residuals are smaller than Innovus's own
  delay-calculation sensitivity. Turning SI-aware delay calculation off moves the
  reference from -0.006 / +0.006 ns to -0.056 / +0.062 ns. It moves the trial from
  +0.028 / -0.023 ns to -0.019 / +0.047 ns.
- **Same-path check.** On the reference's failing path, PT times the same 150 pins
  and transitions at +0.280 ns (PR #24).

## Limits

- **Four-lane setup is not closed.** Innovus misses by 6 ps with SI-aware delay
  calculation and by 56 ps without it, on the lane-3 RNG output path. That path is
  two chained 32-bit additions in one cycle. A latency-preserving look-ahead
  register has been proposed to the RNG owner but is not implemented or verified.
  Four-lane operation at 5 ns is therefore not established.
- **Zero-limit capacitance checks are unresolved.** Seven library output pins
  declare `max_capacitance : 0`: AOI21X1/Y, AOI22X1/Y, DFFSR/Q, NAND2X1/Y,
  NAND3X1/Y, NOR2X1/Y and TBUFX1/Y. Every max-capacitance row in both
  implementations is on these pins, so buffering cannot remove them. No pin with a
  positive limit violates. Changing the limits would be another library
  approximation that needs course-staff approval, so the rows stay reported as
  unresolved violations.
- **RC and PPA are estimates.** They rest on native RC without a characterized
  capacitance table, one typical corner and zero-delay activity for one workload.
  The library tables are evaluated below their first index on the critical path.
  On the four-lane path, Innovus is 0.260 ns slower than PT over identical arcs
  (PR #24).
- **Signoff is incomplete.**
  - Neither tool ran multi-corner, on-chip-variation or SI signoff; PT ran
    without SI.
  - There is no foundry DRC/LVS, extraction signoff, IR/EM analysis or
    SDF-annotated simulation. The replays are zero-delay.
  - PT leaves 4,538 / 7,130 / 12,326 timing checks untested (45 to 46%). Most are
    asynchronous recovery/removal and minimum-pulse-width checks; setup and hold
    each leave one check untested.
  - At four lanes, Innovus's own DRV summary lists one max-transition net at
    -0.001 ns, which PT does not report.
  - RC-004 input-driver warnings remain.
  - No rated maximum frequency is claimed.

## Figures and evidence for the editor

- **Figures.** `results/multilane_setup_fixed_v1.png` and
  `results/multilane_closure_v1.png`. Caption: "Matched 1/2/4-lane results at 5 ns:
  mapped cell area, throughput conditional on timing closure, estimated power and
  energy per trial, for the PR #22 baseline and the hold/fanout policy." Panel a
  shows DC area, which is the same in both. Show the policy's cost with the table
  above, not the panel.
- **Canonical tables.**
  - `results/multilane_setup_fixed_v1.{csv,md}` and
    `results/multilane_closure_v1.{csv,md}`.
  - Their run manifests: `reports/multilane_setup_fixed_v1_runs.csv` and
    `reports/multilane_closure_v1_runs.csv`.
  - The original-library implementation of PR #21 stays separate, in
    `results/multilane_implementation.{csv,md}`.
- **Raw evidence per run.** `<tag>` is `setupfix_v1_20261123`,
  `tyler_closure2_20261123` or `tyler_closure3_20261124`.
  - Areas: `reports/pnr/<tag>_l<N>/implementation.rpt`.
  - Innovus setup and hold: `postroute/mc_top.summary.gz` and
    `postroute_hold/mc_top_hold.summary.gz`.
  - Hold cells: the "Added a total of N cells" lines in
    `reports/pnr/<tag>_l<N>.log`.
  - PT: `summary.txt`, `power.rpt`, `coverage.rpt` and `reset_timing.rpt` under
    `reports/sta/`. The baseline runs end in `_routed_validated`, the others in
    `_routed_final`.
  - Violation rows: `violators.rpt`, classified by `scripts/classify_violations.py`.
  - Replays: `reports/sim/<tag>_l<N>_routed/run.log`.
  - SI sensitivity: `reports/pnr/*_l4/diagnostics_si/`.
- **Integration evidence.** `reports/integration_validation_2026-11-01.txt`,
  `reports/interim_validation_2026-11-11.txt`,
  `reports/pr_review_validation_2026-11-23.txt` and
  `reports/pr_review_2026-11-23/pr17-vcs-summary.txt`.
- **Method and root causes.** `docs/Timing_Electrical_Closure.md`,
  `docs/Library_Fix_Baseline.md` and `docs/Multilane_Implementation.md`.
- **PR #24**, pinned to `0fa27ec`: the
  [RNG path note](https://github.com/chuanqichen/Hardware-Accelerated-Monte-Carlo-Simulation/blob/0fa27ec17e4915e8adff68ae2043215dd50fec1a/docs/RNG_Setup_Path_Diagnostic.md),
  the [same-path comparison](https://github.com/chuanqichen/Hardware-Accelerated-Monte-Carlo-Simulation/tree/0fa27ec17e4915e8adff68ae2043215dd50fec1a/reports/sta/tyler_rngdiag_20261124_l4),
  the [trial manifest](https://github.com/chuanqichen/Hardware-Accelerated-Monte-Carlo-Simulation/blob/0fa27ec17e4915e8adff68ae2043215dd50fec1a/reports/lab_artifacts/tyler_closure3_20261124/MANIFEST.md)
  and the [validation record](https://github.com/chuanqichen/Hardware-Accelerated-Monte-Carlo-Simulation/blob/0fa27ec17e4915e8adff68ae2043215dd50fec1a/reports/closure_followup_validation_20261124.txt).
- **Rounding.** Slacks in the tables are rounded to 1 ps. The full values are in
  the CSVs and summaries.
