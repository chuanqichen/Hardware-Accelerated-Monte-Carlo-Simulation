# Second RNG experiment: verified carry-select timing improvement

**Standalone screening passed: +0.597332 ns setup slack at 5 ns. Physical
implementation, routed timing and electrical signoff remain pending.**

Branch `shentong/rng-t-update-carry-select` is based on PR #27 commit `30caa47`.
This candidate is the second commit of draft PR #27; the first prototype commit
and all of its reports remain in history. Fresh lab runs completed
2026-11-27 under Shentong's own account, `sz23492@mario.ece.utexas.edu`, in
`/misc/scratch/sz23492_rng_jFY87fxx/t_update_Dbhsv3Oy`.

## What changed and why it preserves behavior

The first prototype's resource report combines seed-load and next-state sums in
one `DP_OP_15J1_122_1981` adder. Its worst path starts at `run`, passes through
operand-selection logic and a long FAX1 carry chain, and ends at `t_reg[31]`.
Its +0.00337601 ns slack failed the screen against main's +0.00604582 ns.

The second candidate retains a normal 32-bit seed sum but spells the next-state
sum as four 8-bit carry-select blocks. The low block establishes carry; each
upper block selects a result computed for carry-in zero or one. Each block uses
9-bit intermediates; discarding the last carry gives exactly the low 32 bits of
`s0_next + s3_next`. No full-width '+' operation remains in that next-state cone
for DC to share with the full-width seed addition.

The t invariant, asynchronous reset, reset > seed_load > run > hold priority,
zero-seed inhibition, canonical output stream, u/u_valid edges and LAT_RNG=1
remain unchanged. Storage stays at 193 bits; no pipeline stage, synthesis
attribute, retiming, library, constraint, model or shared-flow change was made.
The additional cost is combinational logic. Only rng_lane RTL and its short
testbench change relative to the first prototype.

## Completed verification

Each of the three versions (unchanged main, first prototype, candidate) passed:

- `make rng-test`: 9 tests; full model suite: 109 tests, no skips.
- `make rng-sim`: 4,440 cycles and 1,763 valid words.
- Four top-level G/M configurations, each 22 cases and 26,457 exact trials,
  with sustained II=1; lane-bubble regression: 100 exact trials.
- Three canonical RTL streams of 1,048,576 words each, checked for exact output,
  exact state and II=1, plus imported-stream canonical and quality checks.

The candidate additionally passed **4,193 exact modular-addition checks**:
overflow cases, carry propagation at every bit boundary and 4,096 reproducible
random operand pairs. Existing tests assert t after reset, load, accepted run and
pause, and check first-word timing, pause/resume without skipped samples, load
priority, zero-state inactivity and asynchronous reset between clock edges.

Tools: Python 3.9.25, numpy 2.0.2, matplotlib 3.9.4 and VCS T-2022.06_Full64.
Local Windows checks also passed the 109 model tests, diff whitespace checks
and the tracked-evidence artifact audit. These local model checks supplement,
and do not replace, the completed lab RTL simulation.

## Fresh matched synthesis

All three use DC **T-2022.03-SP2**, the default `setup_fixed_v1` pair, typical
corner, identical `lane_5ns.sdc`, 5.0 ns period, 0.10 ns setup uncertainty,
`compile_ultra -no_autoungroup`, the shared area optimization and `RETIME=0`.
The three tags are `t_update_Dbhsv3Oy_{main,proto1,proto2}`. All three were freshly
run in this session; the November 8 measurement is not the baseline.

| Metric | Main | First prototype | Carry-select candidate |
|---|---:|---:|---:|
| Setup slack (ns) | +0.00604582 | +0.00337601 | **+0.597332** |
| Cell area (um2) | 5274.931992 | 6082.127993 | 6335.080712 |
| Cells | 1568 | 1711 | 1764 |
| Registers | 161 | 193 | 193 |
| Critical startpoint | s0_reg[0] | run | seed_state[0] |
| Critical endpoint | u_reg[31] | t_reg[31] | t_reg[31] |
| Reported hold-violating paths | 0 | 0 | 0 |
| Capacitance violation rows | 516 | 426 | 540 |
| Transition/fanout violations | 0 / 0 | 0 / 0 | 0 / 0 |
| Worst reported reset recovery slack (ns) | +2.82 | +2.82 | +2.82 |
| Worst reported reset removal slack (ns) | +1.30 | +1.40 | +1.40 |
| Max-leakage-power constraint cost (VIOLATED) | 5596.8135 | 6840.6484 | 6733.6685 |

Candidate slack gain is **+0.59128618 ns versus main**, and +0.59395599 ns versus
the first prototype. Area is **20.10% above main** and **4.16% above prototype 1**;
it adds no registers relative to prototype 1. It exceeds the approximately +0.3 ns
standalone screening target. This is a measured pre-layout margin at one corner,
not a claim of routed closure or a rated maximum frequency.

### Mapping and critical path

The candidate resource report separates the 32-bit output and seed adders
(`add_x_1`, `add_x_2`) from a 9-bit low-block adder and smaller DP_OP blocks for
the upper next-state byte sums. DC shares each upper block's zero-carry sum with
its plus-one variant; it no longer reports the full-width seed/next-state shared
adder of prototype 1. This establishes the intended structural change, without
claiming that every logic mux remained in its RTL position.

The candidate top five paths start at `seed_state[0]` and end at t[31:27]. The
worst enters seed selection logic, then `intadd_0/U31/YC` through `U3/YC` FAX1
carry stages, `U885/YS`, `U1836/Y`, and `U1866/Y` into `t_reg[31]/D`. Including
1.50 ns input delay, data arrives at 4.18 ns against a 4.77 ns requirement
(rounded). Use summary.txt for the unrounded +0.597332 ns slack. The previous
run-controlled path is no longer among the top five; its exact margin is not
reported there and must not be inferred.

### Retained violations and limitations

All constraint reports show zero setup/min-delay cost and MET transition,
fanout and clock-pulse checks. Reset reports give the margins above; timing_check
reports no unconstrained-endpoint warnings. The PPA parser's 0.0 hold-slack field
is a summary/default, not a detailed minimum-hold measurement or routed signoff.

The candidate retains **540 max-capacitance rows**, versus 516/426 in the controls.
Required limits all print as 0.00 at default report precision. Do not infer from
rounded text that every limit is exactly zero, or certify that every positive
limit passes. Zero-limit capacitance issues remain separately unresolved pending
a TA/professor decision and are not waived. Max-leakage-power is also marked
VIOLATED; table values are report costs, not power measurements in mW. All three
parsed PPA rows remain `mapped_with_violations`.

All versions retain VER-318 (mc_pkg signed/unsigned conversion) and UID-401
(driving-cell port attributes). Prototype 1 also retains two LINT-1 elaboration
warnings. Candidate check_design.rpt returns 1 without those LINT-1 warnings.
No mapped/routed cell replay or physical implementation was run.

## Evidence and input audit

New raw reports/logs/manifests: `reports/{syn,sim}/t_update_Dbhsv3Oy_{main,proto1,proto2}/`.
Parsed measurements: `results/t_update_Dbhsv3Oy_{main,proto1,proto2}_*`.
Comparison CSV: `results/rng_t_update_Dbhsv3Oy_comparison.csv`.
Input manifest, exact comparison runner, original input note and terminal logs:
`reports/lab_artifacts/rng_t_update_Dbhsv3Oy/`.

Downloaded results archive SHA256:
`e4fa61c77ed7358cc322c81d3e74ddf902a0e73ec305c351d80ebf42b7a24edb`.
Original input bundle (`rng_t_update_lab_v2.tar.gz`) SHA256:
`0913faea6dd395fc98360827c2a02a1a192d899e8d7756a5c655fd25fca3dbc3`.
The wrapper verified all 157 bundle input hashes before copying or running.

All **132 source-manifest entries per version** were independently compared with
main f137a6c plus the intended prototype files: no mismatches. Downloaded candidate
patch bytes match the current working RTL/testbenches exactly. Exact lab source
bytes are preserved under `reports/sim/t_update_Dbhsv3Oy_proto2/source_snapshot/`;
Git normalizes the working source CRLF to LF, so compare normalized bytes against
Git and exact bytes against the recorded hashes. Both control results reproduce
the earlier matched measurements exactly.

DC records identical package, constraint and flow-script hashes, same tool and
settings, and identical library DB hash:
`dd8d0571337905400b247e75069d77fdab50f1d1520442d91cf8df8e39e1d256`.
The wrapper also compares both library formats across all three copies. Source
exports have no Git directory; their `source_export` revision is tied to the
pinned baseline and intended diffs by these hashes, not by a lab Git revision.

Raw reports are preserved under new tags; prior committed reference results,
shared libraries and constraints are unchanged. Simulator binaries, DC work/DDC/
SVF and long hex streams are omitted from the downloaded archive; long streams
and short VCDs remain on lab scratch. Logs record the exact stream checks.

## Reproduction and next handoff

Use your own lab login, the same `synopsys/2022` module and Python environment.
Unpack the recorded input bundle into a fresh owned scratch directory and run
`PYTHON=/path/to/your/venv/bin/python bash run_comparison.sh` there. The script
validates the bundle, creates isolated proto1/proto2 copies of main, compares
settings, runs the same validation script with three million-word streams and
DC included for each version, then packages evidence. It stops on failure and
refuses existing prototype directories. Choose a fresh directory for every trial;
do not overwrite old tags or regenerate reference data in place.

This candidate is ready for review as a successful standalone timing experiment.
Present it as the final candidate in draft PR #27. The preceding negative-result
commit and measurements document why this revision was necessary.
Tyler owns the next matched 1/2/4-lane implementation with the tyler_closure2
policy and fresh tags. Acceptance still requires setup/hold in both tools,
fanout/transition/reset and positive-capacitance checks, geometry/connectivity and
mapped/routed replay, while reporting unresolved zero-limit rows separately.
No physical closure or full electrical signoff is claimed by this handoff.
