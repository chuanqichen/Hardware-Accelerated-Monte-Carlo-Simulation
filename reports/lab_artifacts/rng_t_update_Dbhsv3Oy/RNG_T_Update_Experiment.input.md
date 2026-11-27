# Second RNG experiment: t-update carry select

Branch: `shentong/rng-t-update-carry-select`, based on PR #27 commit `30caa47`.
The first prototype and its measured reports remain unchanged on their branch.
This revision is an experiment; no new timing or HDL-pass result is claimed.

## Evidence and hypothesis

The first prototype's `resources.rpt` explicitly combines the seed-load and
next-state additions in `DP_OP_15J1_122_1981`. The mapped worst path starts at
`run`, traverses control/operand-selection logic, then the FAX1 carry chain and
ends at `t_reg[31]`, with +0.00337601 ns setup slack. Fresh unchanged main had
+0.00604582 ns; the first prototype therefore failed the timing screen.

## Revision

Keep the seed sum as a 32-bit addition. Compute the next-state sum independently
with four 8-bit carry-select blocks: the low block produces its carry; each
upper block computes both carry-in possibilities, then selects the appropriate
9-bit result. The low 32 bits equal `s0_next + s3_next` modulo 2^32. Carry out of
the top block is intentionally discarded. This spelling removes the identical
full-width '+' operations that DC shared in the first prototype. Mapping may
still optimize or restructure it; inspect actual reports before claiming that
run-dependent selection moved after arithmetic or that timing improved.

The asynchronous reset, seed/run/hold branches, t invariant, 193 state bits,
canonical output function, u/u_valid timing and LAT_RNG=1 are unchanged. No
extra register/stage, synthesis directive, retiming, constraint or library change
is introduced. Potential cost is extra combinational area.

The existing invariant and cycle/stream oracles remain. The short testbench adds
4,193 independent full-width arithmetic comparisons: directed overflow, carry
propagation at every bit boundary, and 4,096 reproducible random operand pairs.
The long canonical streams and integration tests are still mandatory.

## Validation status and next lab step

Local checks: 109 Python model tests and the tracked-evidence artifact audit passed;
`git diff --check` passed. HDL simulation and synthesis for this revision are pending. Python model checks
cannot establish that the new RTL simulates or maps correctly. Use fresh, isolated
copies of unchanged main, PR #27 prototype and this candidate, with the same lab
module, Python, default setup_fixed_v1 library pair, lane_5ns.sdc, 5 ns clock,
shared synthesis settings and RETIME=0. Use fresh tags through
scripts/run_rng_validation.py, with --words 1048576 --streams 3 and synthesis
included. Retain the logs, input hashes, timing/resources reports, area, register
counts and all violations for all three versions.

For the candidate, require both `PASS rng_t_adder: 4193 exact modular sums` and
the existing rng_lane PASS marker in rng_sim.log. Inspect resources.rpt and the
worst setup path to determine whether full-width seed/run adder sharing persists
and whether a new seed or output bottleneck appears. Approximately +0.3 ns slack
is a screening target, not proof of routed closure. No physical flow is requested.
