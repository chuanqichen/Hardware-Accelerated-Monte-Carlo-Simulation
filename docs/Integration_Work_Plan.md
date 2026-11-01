# Integration, control, and tool flow

Owner: Tyler Haverlah. Verified publication checkpoint: 2026-11-01.

## Scope and source

The one-lane top integrates Shentong's RNG, Chuanqi's Gaussian LUT and package,
Eric's pricing datapath and accumulator, and Tyler's configuration/controller.
PR #4 (shared infrastructure) and PR #5 (synthesis/reset) are approved and merged.
The false-pass test gate was fixed and merged through PR #6 before approving #4.

The active implementation branch is tyler/one-lane-integration, in the worktree
HardwareAcceleratedMonteCarlo/.worktrees/one-lane-integration. The original dirty
October 18 checkout is preserved. Tyler authorized publication and merging on
November 1. No Slack message is sent by this task. The shared flow has one canonical
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

- 69 model tests and 12 configuration/parser tests pass.
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

## Shared 5 ns synthesis result

The full top was mapped by DC T-2022.03-SP2 using gscl45nm typical 1.1 V/27 C and
PR #5's shared constraints, with recovery/removal arcs enabled. Area is 33,016.193446
um^2. Setup slack is +0.000509739 ns, roughly 0.51 ps: nominally met with negligible
margin. There are 135 hold violations (worst -0.04 ns), 4,471 capacitance violations,
and no transition violations. No unconstrained endpoints are reported. Sampled
reset recovery/removal paths are reported separately and met in this run.

These are pre-layout estimates, not physical signoff. Clocks are ideal and wiring
is not extracted. Reported 4.7455 mW power uses unannotated inputs, and slack-derived
Fmax is not an achieved-frequency claim. Fix electrical/hold issues and establish
routed margin before claiming 200 MHz operation or energy per trial. Historical
10 ns results remain in results/one_lane_synthesis.csv; use the current
results/one_lane_shared_5ns.csv for the shared-flow baseline.

## Evidence and reproduction

Commands are in scripts/README.md. Inputs are committed baseline ROMs and vectors;
regenerate deliberately with model scripts. Production source lists exclude mocks.
Use unique run tags. The flow validates inputs, refuses overwrite, records source
and library hashes, and retains timing/electrical violations in the parsed CSV.

Current raw reports: reports/syn/mc_top_shared_5ns/. Validation summary:
reports/integration_validation_2026-11-01.txt. Local VCS logs/manifests:
reports/sim/top_combined/, bubbles_combined/, control_combined/, rs_combined/.
No standard-cell library/model file or licensed executable was copied into the repository.

Tests used an isolated owned /home/work/teh969/monte_carlo directory on mario.
The shared home quota is full; no unrelated files were moved or deleted. The
original October 18 checkout remains intact. Commit/run manifests preserve the
source snapshot; source-code whitespace checks exclude unchanged raw tool reports.

## Handoff

Codex owns the final publication step for Tyler. After merge, release this writer
and recheck main before the next edit. Remaining work: cfg agreement, gate-level
simulation, independent STA, hold/capacitance cleanup and physical implementation,
then real 2/4-lane reduction and seed policy. No further RTL feature work belongs in
this merge checkpoint.
