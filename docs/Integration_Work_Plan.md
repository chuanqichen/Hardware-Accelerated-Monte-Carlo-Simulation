# Integration, control, and tool flow

Owner: Tyler Haverlah. Current local checkpoint: 2026-10-31.

## Source and ownership

The active checkout is `HardwareAcceleratedMonteCarlo/.worktrees/one-lane-integration`,
branch `tyler/one-lane-integration`, based on PR #4 head `c6da2ad` (not merged).
Codex is the sole writer for this local integration change. The original checkout
on `tyler/week1-control-synthesis` and its uncommitted October 18 work are preserved.
No GitHub review, merge, push, team message, or approval was published.

This branch depends on PR #4. Merge that prerequisite or restack after its review
before publishing the integration. The Git-managed worktree was used because the
native worktree tool rejected the nested repository as a source root.

## Implemented integration

`mc_top` now connects our controller/configuration to the production
`mc_lane_array`: Shentong's RNG, Chuanqi's Gaussian block, Eric's pricing datapath,
and Eric's accumulator. `mc_pkg` supplies the status bits, register map, and latency
formulas. No teammate arithmetic source was modified. In particular, replacing
price_dp's existing inline rounding with shared round_sat remains Eric's follow-up;
the current implementation and the Python model already agree bit for bit.

The production adapter supports **one lane**, baseline Gaussian/exp address bits
10 and Q3.12 Gaussian output. GAUSS_LATENCY and MUL_STAGES support 1 or 2. The
1/2/4-lane control mock remains a separate test target and is excluded from
production synthesis. No multi-lane reduction tree or independent seed policy is
claimed by this checkpoint.

LOAD loads the RNG seed and clears the accumulator. The same clear flushes only
the downstream pipeline valid bits; resetting the RNG on that edge would suppress
seed loading. Completion uses the actual completed trial count. Measured run cycles
are `N + mc_pkg::lat_total(GAUSS_LATENCY,MUL_STAGES,1) + 2`, including start and done.
For the default latency configuration, this is N+11 cycles.

The accumulator reports sticky saturation flags. The top must ignore the previous
run's flags during LOAD before clear takes effect. That integration correction is
covered by a saturated run followed immediately by a normal run.

## Candidate configuration contract

The top uses the draft write-only cfg bus, software-provided 128-bit seeds, and
a two-edge reset release synchronizer. Accepted start latches A/B/K/seeds and clears
sticky status for the new run. Busy start pulses are ignored. Busy writes are
ignored and set bad_cfg. Zero trials or a zero seed rejects start and preserves
results. Unknown addresses and nonzero reserved high bits are ignored and flagged.
A configuration-write/start collision rejects start but permits the idle write.
These concurrency clarifications still need team agreement. The 32-bit cycle
counter wraps for runs exceeding its range; it freezes while idle.

## Verified results

- PR #4's unchanged Python suite: 69 tests passed. Local setup/parser suite: 9 passed.
- VCS T-2022.06: 22 full-top cases at each of four Gaussian/multiplier latency
  combinations, 105,828 trial comparisons total. Every u, z, x, S_T, payoff, flag,
  final sum/count/status, and cycle count matched the PR's unmodified lane model.
- Cases include N=1/100/1000/10000, all five option scenarios, three deterministic
  seeds, x/exp saturation, saturated-to-normal restart, and reset during flight.
- Sustained one-payoff-per-cycle output was checked after pipeline fill. An
  additional 100-trial real-adapter test verified pause/resume and bubble alignment.
- Existing controller-only tests: ten runs each at LANES=1/2/4 passed with the mock.
- Independent review of round_sat's original vectors: 12,067 signed and 11,552
  unsigned comparisons passed. A separate harness defect is recorded in the shared
  2026-10-31 handoff document; no arithmetic defect was found in the reviewed scope.

The full top synthesized using DC T-2022.03-SP2 and the course gscl45nm library,
typical at 1.1 V/27 C. At the initial 10 ns constraint, setup slack is +4.65 ns,
critical path 5.06 ns, and cell area 39,412.75236 library units. There are 1,047 hold
violations (worst -0.20 ns) and 4,702 max-capacitance violations. No unconstrained
endpoints were reported. Reports use ideal clocks and no wire-load/extracted routing.
These are synthesis smoke results with violations, not physical timing signoff,
Fmax, power, or energy evidence. Parsed data is in `results/one_lane_synthesis.csv`.

## Reproducibility and evidence

See `scripts/README.md` for commands. Vector generation uses `model/mc_lane.py`
without reimplementing its arithmetic. `make sim-top` and `make sim-lane-bubbles`
use explicit committed/generated vectors and require final nonempty PASS markers;
they do not silently regenerate the ROMs. Production source lists exclude mocks.

Raw local evidence is under `reports/sim/top_integrated_v2/`,
`reports/sim/lane_bubbles/`, `reports/sim/control_integrated/`,
`reports/syn/top_integrated/`, and `reports/review/`. Source manifests identify the
executed uncommitted inputs. All simulation/synthesis hashes match local LF-normalized
files. Logs are gitignored; retain them or deliberately include/export evidence when
publishing. Libraries, models, licensed databases, and compiled executables were not
copied into this repository.

The isolated lab workspace is recorded in `reports/integration_remote_path.txt`.
Builds use `/home/work/teh969/monte_carlo/` on mario. The account's shared home quota
is full; an earlier attempt hit a linker failure after three passing configurations.
No unrelated files were deleted or moved. All final configurations passed on local
disk. VCS lint still reports benign testbench sizing/label notes and the pre-existing
exp2_unit signed comparison note; lint-clean status is not claimed.

## Handoff and next action

Writer released after this checkpoint; next writer acceptance pending. Keep this
snapshot stable during review. Resolve the PR #4 harness finding and team cfg rules,
then publish/review this integration when authorized. Improve synthesis constraints
and investigate hold/capacitance violations before the physical flow. The next
architecture milestone is an explicit registered reduction tree and jump-separated
seeds for 2/4 lanes. Accuracy budgets and the interim presentation remain team work.

## Authorized merge work, 2026-11-01

Tyler authorized publication, merging, and approval when ready. Codex has accepted
writer ownership in this checkout. The October 31 snapshot is being checkpointed
before PR #4 harness hardening and reconciliation with PR #5. Original Week 1
checkout remains preserved. Do not start another writer in this checkout.
