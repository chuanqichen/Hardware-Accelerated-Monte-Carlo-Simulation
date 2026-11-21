# Integration, control, and tool flow

Owner: Tyler Haverlah. Verified interim checkpoint: 2026-11-11.

## Scope and source

The one-lane top integrates Shentong's RNG, Chuanqi's Gaussian LUT and package,
Eric's pricing datapath and accumulator, and Tyler's configuration/controller.
PR #4 (shared infrastructure) and PR #5 (synthesis/reset) are approved and merged.
The false-pass test gate was fixed and merged through PR #6 before approving #4.

The current update starts from main a83501c, including merged PRs #7–#10, on
tyler/interim-integration-update in HardwareAcceleratedMonteCarlo/.worktrees/interim-update.
The original dirty October 18 checkout is preserved. Slack and the shared interim
draft were read for requirements; Shentong is assembling the shared report. The
report contribution is docs/Interim_Integration_Contribution.md. The shared flow has one canonical
dc_synth.tcl and parser, with the old-format parser retained for historical reports.

## Implemented contract

Production supports LANES=1, Gaussian/exp address bits 10, Q3.12 output, and
GAUSS_LATENCY/MUL_STAGES each 1 or 2. Multi-lane control masking is tested with a
separate mock; real 2/4-lane reduction and independent seeds are future work.

The top uses mc_pkg status bits and cfg addresses and PR #5's two-stage rst_sync.
LOAD loads the RNG seed, clears the accumulator, and flushes downstream valid bits.
The RNG is not held in reset on its seed-load edge. Completion depends on actual
completed trials. The top ignores old accumulator flags during LOAD; a saturated
run followed by a normal run checks that flags do not leak across runs.

Measured busy-run cycles are N + lat_total(GAUSS_LATENCY,MUL_STAGES,1) + 2; default
N+11. Configuration and reset-release time are outside this cycle counter.
The output stream sustains II=1 after fill in RTL simulation. This does not alone
establish routed frequency or host-to-host throughput.

Accepted start latches A/B/K/seeds and clears new-run status. Busy starts are ignored.
Busy writes, unknown addresses, reserved high bits, zero trials/seeds, and concurrent
write/start are flagged according to the implemented candidate contract. The latter
rejects start while allowing the valid idle write. Results hold while idle; cycle
count wraps modulo 2^32 on extremely long runs. These cfg concurrency details remain
subject to team agreement. Numeric functions were not rewritten; Eric's inline
rounding remains numerically equivalent pending his shared-module drop-in.

## Verification

- 85 model tests and 21 flow/runner tests pass at this checkpoint (18 existing
  flow tests plus 3 new PrimeTime-runner tests).
- Four full-top latency combinations pass 22 cases each: 105,828 trial comparisons.
  Every qualified u, z, x, S_T, payoff, flag, final sum/count/status, and cycle count
  matches the unmodified lane model. Cases cover N=1/100/1000/10000, all five option
  scenarios, three seeds, saturation, saturated-to-normal restart and reset in flight.
- The real-adapter 100-trial bubble/pause/resume test passes. The control-only
  regression passes ten runs each at 1/2/4 lanes with the mock.
- The corrected rounding runner passes 12,067 signed and 11,552 unsigned vectors;
  empty, missing, mismatching and malformed inputs each return failure.
- All seven published Gaussian area/slack/power rows are preserved by the consolidated
  parser. Source hashes match the tested exported Git tree, including line endings.
- Shentong's November 8 archive repeats the four full-top configurations and bubble
  test on the current runtime sources. On November 11 a fresh mapped netlist passed
  22 cases / 26,457 trials in tb_mc_top_gate: interface results/status, reset/restart,
  and exact busy-cycle counts. This is zero-delay functional cell simulation, not
  SDF simulation or formal equivalence. Corrupted expected sums and empty corpora
  return failure. PrimeTime's runner also rejects an invalid SDC and exit-zero errors.

## Shared 5 ns synthesis and independent timing results

The November 11 full top was mapped by DC T-2022.03-SP2 using gscl45nm typical
1.1 V/27 C and shared constraints, with recovery/removal arcs enabled. Area is 33,016.193446
um^2. Setup slack is +0.000509739 ns, roughly 0.51 ps: nominally met with negligible
margin. There are 135 hold violations (worst -0.04 ns), 4,471 capacitance violations,
and no transition violations. No unconstrained endpoints are reported. Sampled
reset recovery/removal paths are reported separately and met in this run. These
metrics reproduce the November 1 synthesis baseline.

Independent PrimeTime T-2022.03-SP5, reading that run's mapped netlist, exported
SDC and the same library digest, reports setup slack -0.200381 ns and hold slack
-0.041280 ns. Thus the 5 ns target is not independently closed. The worst path is
active_b_reg_3_ to u_lanes/u_price/acc_r_reg_0__32_. Data arrival agrees with DC at
the latter's displayed precision, while the endpoint library setup term differs:
DC prints -1.22 ns and PrimeTime -1.417704 ns. The root cause remains open; do not
change constraints or waive paths merely to reconcile the result.

Coverage reports one violated setup check, 135 violated hold checks and 4,538
untested checks overall. check_timing warns about 755 asynchronous S pins without
clocks. Constant/unused arcs and reset-check coverage need classification; no
coverage signoff is claimed. The zero max_leakage_power optimization target also
produces a constraint diagnostic in synthesis, as in the RNG study. It is retained
for shared-flow review rather than hidden in the power estimate.

These are pre-layout estimates, not physical signoff. Clocks are ideal and wiring
is not extracted. Reported 4.7455 mW power uses unannotated inputs, and slack-derived
Fmax is not an achieved-frequency claim. Fix electrical/hold issues and establish
routed margin before claiming 200 MHz operation or energy per trial. Historical
10 ns results remain in results/one_lane_synthesis.csv; use the current
results/one_lane_interim_5ns.csv for the refreshed baseline and
results/one_lane_interim_sta.csv for the independent timing check. Measured busy
cycles and conditional target-frequency throughput are in
results/one_lane_interim_throughput.csv and the matching figure.

## Evidence and reproduction

Commands are in scripts/README.md. Inputs are committed baseline ROMs and vectors;
regenerate deliberately with model scripts. Production source lists exclude mocks.
Use unique run tags. The flow validates inputs, refuses overwrite, records source
and library hashes, and retains timing/electrical violations in the parsed CSV.

Current raw reports: reports/syn/mc_top_interim_20261111/,
reports/sta/mc_top_interim_20261111_clean/ and reports/sim/gate_interim_20261111/.
Validation: reports/interim_validation_2026-11-11.txt and the source manifest.
Historical validation: reports/integration_validation_2026-11-01.txt. Local VCS logs/manifests:
reports/sim/top_combined/, bubbles_combined/, control_combined/, rs_combined/.
No standard-cell library/model file or licensed executable was copied into the repository.

Tests used an isolated owned /home/work/teh969/monte_carlo directory on mario.
Builds stay off the quota-limited home directory; no unrelated files were moved or deleted. The
original October 18 checkout remains intact. Commit/run manifests preserve the
source snapshot; source-code whitespace checks exclude unchanged raw tool reports.

## Handoff

Tyler/Codex owns this isolated interim update until publication. The new mapped
functional and pre-layout STA flows are exercised, and detailed raw evidence is
retained. Next: reconcile the timing-engine discrepancy and coverage, agree cfg
semantics, address hold/capacitance and physical implementation, then integrate real
2/4-lane reduction and seed delivery. The proposed dated schedule and report-ready
response to the professor are in Interim_Integration_Contribution.md. Shentong
retains ownership of assembling the shared report. No production arithmetic or
RTL changed in this checkpoint.
