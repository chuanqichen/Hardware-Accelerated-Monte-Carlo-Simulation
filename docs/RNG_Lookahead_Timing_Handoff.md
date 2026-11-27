# First RNG look-ahead experiment: historical negative timing result

**Historical first experiment at commit 30caa47:** functional checks pass, but
this version does not improve standalone setup slack. The second commit of
draft PR #27 supersedes it; see [the carry-select handoff](RNG_T_Update_Experiment.md)
for the final candidate and its +0.597332 ns standalone setup slack. Physical
closure remains pending. The measurements below are preserved unchanged.

Branch: `shentong/rng-lookahead-timing`. Baseline is unchanged main
`f137a6cfff27f0a19ab8878268a192df1af88f7d`, checked before editing. No pre-existing
working changes were present. This branch is prepared as a draft PR; no merge
into main is requested. Lab runs completed
2026-11-27 as `sz23492@mario.ece.utexas.edu`, in
`/misc/scratch/sz23492_rng_jFY87fxx/{main,proto}`.

## Change and correctness

`rtl/rng_lane.sv` adds a 32-bit `t` holding `(s0 + s3) mod 2^32`.
Reset establishes the invariant at zero; seed loading establishes it from the
seed's s0 and s3; each accepted run establishes it for the next state using
`s0_next + s3_next`. Holds preserve both state and `t`. All operands and
assignment destinations are 32 bits, so overflow intentionally wraps.

At an accepted edge, nonblocking assignments read old state and old `t`.
Consequently `u <= rotl(t, 7) + s0` equals the original canonical output function.
The state transition, reset > seed_load > run > hold priority, zero-state
inhibition, output clearing on load/reset, and valid bubble on hold are unchanged.
There is no added output stage: `LAT_RNG = 1`. For seed (1,2,3,4), the first
accepted edge yields `0x00000281`, and the second yields `0x00180387`.

The output expression now contains one addition. The added state path contains
XORs and an addition; seed loading also computes a sum. DC confirms the storage
increase from 161 to 193 registers. Shared libraries, constraints, models,
generated RTL, vectors, synthesis settings and committed reference results are
unchanged. All new evidence uses fresh tags. No physical implementation was run.

## Completed verification

Local Windows / Python 3.13: 9 RNG tests and the full 109-test model suite passed;
`git diff --check` passed. Initial local VCS/DC attempts were unavailable.
Subsequent licensed lab runs completed the checks below for BOTH versions:

- 109 model tests: OK (lab Python 3.9.25, numpy 2.0.2, matplotlib 3.9.4).
- `make rng-sim`: **4,440 cycles, 1,763 valid words**, VCS T-2022.06_Full64.
  Prototype `make rng-test` separately passed all 9 RNG tests before full runs.
- `sim-top`: all four G/M configurations, each 22 cases and 26,457 trials,
  exact traces/results and sustained II=1.
- `sim-lane-bubbles`: 100 exact trials, pause/resume and valid latency checks.
- Three independently checked canonical RTL streams, each **1,048,576 words**,
  with II=1 and exact state/output checks. Seeds:
  `0123456789abcdef0fedcba987654321`,
  `a21ddd67452a68254e0d1fe67c4a7a02`,
  `d797cc57f76cbec03fa0faa564fe5eaf`.
- Imported-stream canonical check and RNG screening: PASS for all three streams.

Prototype testbench extensions that passed:

- `tb_rng_lane` asserts modular `t` after every rising edge and asynchronous
  reset, including seed loading, accepted runs and pauses.
- Load beats run, clears output/valid, initializes `t`, and permits the canonical
  first word on the immediately following accepted edge.
- Three paused cycles hold state, `t` and `u`, clear valid, and resume at the
  canonical second word without repeating or skipping a sample.
- Asynchronous reset during active operation, BETWEEN edges with load/run high,
  clears state, `t`, output and valid. Existing vectors check reset priority,
  fresh-seed recovery, zero-seed inactivity, reseeds, wrap and random controls.
- `tb_rng_stream` checks `t` after reset, load, every long-stream edge and pause,
  in addition to its independent canonical state/output oracle.

The first lab baseline attempt (`evidence_9Tku28DS_main`) stopped in Python:
the initial transfer omitted `results/price_dp_ppa.csv` and
`results/accumulator_ppa.csv`, used by pricing-model tests. The exact committed
fixtures were added to both exports without changing them. Fresh tags were used
for the completed pair; the failed evidence remains on the lab machine. A
quality-test negative fixture intentionally prints FAIL; unittest ends in OK.

## Matched synthesis results

Fresh tags: `evidence_ssMPswxD_main` and `evidence_ssMPswxD_proto`.
Both use DC **T-2022.03-SP2**, typical corner, `constraints/lane_5ns.sdc`, 5.0 ns,
0.10 ns setup uncertainty, default `setup_fixed_v1` pair, identical
`compile_ultra -no_autoungroup` / area optimization, and `RETIME=0`.
The November 8 measurement is not used as a baseline.

| Metric | Fresh unchanged main | Prototype |
|---|---:|---:|
| Setup slack (ns) | +0.00604582 | +0.00337601 |
| Cell area (um2) | 5274.931992 | 6082.127993 |
| Cells | 1568 | 1711 |
| Mapped registers | 161 | 193 |
| Critical startpoint | s0_reg[0] | run (input port) |
| Critical endpoint | u_reg[31] | t_reg[31] |
| Reported hold-violating paths | 0 | 0 |
| Max-capacitance violation rows | 516 | 426 |
| Max-transition / max-fanout violations | 0 / 0 | 0 / 0 |
| Worst reported reset recovery slack (ns) | +2.82 | +2.82 |
| Worst reported reset removal slack (ns) | +1.30 | +1.40 |
| Max-leakage-power constraint cost (VIOLATED) | 5596.8135 | 6840.6484 |

Slack delta is **-0.00266981 ns (-2.67 ps)**; cell area increases by
**807.196001 um2 (15.30%)**, with 32 additional registers. Both have small positive
setup slack, but the prototype falls short of the approximately +0.3 ns screening
target and provides no useful overall slack gain.

### Critical paths and interpretation

Baseline top five paths start at `s0_reg[0]` and end at `u_reg[31:27]`, through the
mapped output additions. The worst data arrival and required times both round
to 4.77 ns; use `summary.txt` for the unrounded slack above.

Prototype top five paths instead start at the **run input** and end at
`t_reg[31:27]`. The worst path includes 1.50 ns external input delay, control
logic (`U1423`, `U1629`, `U1533`, `U1536`, `U1144`, `U1537`, `U1998`), then
`DP_OP_15J1_122_1981/U32/YC` through `U3/YC` FAX1 carry stages, followed by
`U1656` XOR, `U1664` mux and `U1665` inverter into `t_reg[31]/D`.
Arrival/required times round to 4.77 ns. Thus the limiting path has moved to
the control-to-look-ahead-register cone. The top-five report does not quantify
margin to `u`; do not infer an output-path slack from its absence there.

A possible next experiment is to investigate arithmetic sharing and operand
selection in the `t` cone, seeking to move run-dependent selection after the
addition. This is an investigation, not a measured fix. Preserve this prototype
as the measured result and use fresh tags and full verification for any revision.
Do not relax the constraints or change the library to make the comparison pass.

### Retained violations and limits

Both `constraints.rpt` files report setup and min-delay/hold cost zero,
max-transition/fanout MET, and no reported reset violations. `reset_timing.rpt`
contains the recovery/removal margins above. `timing_check.rpt` reports no
unconstrained-endpoint or other timing-check warnings. A zero hold-violation
count is not a routed hold signoff or a measured minimum hold margin; the PPA
parser's 0.0 hold-slack field must not be presented as a detailed hold report.

`violators.rpt` retains **516 / 426 capacitance rows**. Their required limits
all print as 0.00 at the report's default precision. That rounded text alone
cannot certify that every limit is exactly zero, or that every positive-limit
check is clean. Do not waive these rows. Zero-limit capacitance issues remain
separately unresolved pending a TA/professor decision; full electrical signoff
is not established. `constraints.rpt` also retains the max-leakage-power costs
above (costs, not mW power measurements).

Both runs retain VER-318 (signed-to-unsigned conversion in mc_pkg.sv) and UID-401
(driving-cell design attributes on ports). Prototype elaboration additionally
reports two LINT-1 warnings that cells C1196/C1264 do not drive any nets;
`check_design.rpt` records these elaboration warnings. The script also ran its
postcompile check_design successfully before emitting SYNTH_DONE.

## Evidence and provenance

Local raw evidence: `reports/{sim,syn}/evidence_ssMPswxD_{main,proto}/`.
Parsed CSVs and quality manifests: `results/evidence_ssMPswxD_{main,proto}_*`.
Read `inputs.txt`, `summary.txt`, `timing.rpt`, `violators.rpt`, `constraints.rpt`,
`reset_timing.rpt`, `timing_check.rpt` and `synthesis.log` for each variant.

The downloaded archive `rng_timing_evidence_ssMPswxD.tar.gz` has SHA256
`764ed8f9424850b735b848d6ef20bd39480abb94eff0196a1cceb861d3f3a1f8`.
It omits simulator binaries, long hex streams, DC work/DDC/SVF and retains logs,
short VCDs, reports, mapped Verilog/SDC, manifests and parsed results.
The long hex streams remain on mario; the logs record their exact checks.

All **132 source-hash entries per simulation manifest** were checked against
baseline Git bytes plus exactly the three intended prototype files: no
mismatches. Downloaded prototype RTL/testbenches also match the local working
files byte for byte before Git staging. Windows core.autocrlf normalizes the
three source files to LF in Git; exact lab CRLF bytes are additionally retained
in `reports/sim/evidence_ssMPswxD_proto/source_snapshot/`, matching the recorded
hashes. LF-normalized snapshot bytes equal the Git source contents.
DC input hashes confirm matching package, constraints and
synthesis scripts; only rng_lane RTL differs. Both DB hashes are
`dd8d0571337905400b247e75069d77fdab50f1d1520442d91cf8df8e39e1d256`.
Before the runs, the shell also compared both Liberty files, DBs and scripts.
Lab source exports have no Git directory, so their manifests say `source_export`;
the checked hashes tie them to the pinned main plus the reviewed diff.

## Handoff decision

The requested prototype and matched evaluation are complete. Functional
verification succeeded; the timing-improvement screening failed. Report this
negative result and the new `run -> t_reg[31]` bottleneck to Tyler before any
physical follow-up. Keep a PR in draft if presenting this implementation for
review; do not merge it as a demonstrated timing fix. No mapped/routed cell
replay or physical run was performed. Tyler owns any subsequent matched
1/2/4-lane implementation and physical acceptance checks in both tools.

## Reproducing the matched comparison

Use your own lab account, key and scratch space per AGENTS.md. On the lab,
start a login shell, load the same tool module for BOTH runs (`module load
syn/2022` on peach; Tyler uses `module load synopsys/2022` on mario), and activate
your own Python >=3.9 environment with numpy and matplotlib. Do not use another
member's account. Begin in a copy of this repository containing the reviewed
three-file implementation/testbench diff (transfer the patch there first).

The following Bash commands create two fresh, separate worktrees. The baseline
is pinned to the unchanged main inspected for this change; prototype inputs are
copied from the reviewed working tree, so no commit is required. Set
`RNG_SCRATCH` to your own large scratch directory and `PYTHON` to your own venv
Python before running. Do not place these worktrees in a quota-limited home.

```bash
set -euo pipefail
: "${RNG_SCRATCH:?Set RNG_SCRATCH to your own scratch directory}"
: "${PYTHON:?Set PYTHON to your own Python >=3.9 venv executable}"
repo=$(git rev-parse --show-toplevel)
base=f137a6cfff27f0a19ab8878268a192df1af88f7d
pair=$(mktemp -d "$RNG_SCRATCH/rng_t_pair_XXXXXXXX")
run_id=$(basename "$pair")
git worktree add --detach "$pair/main" "$base"
git worktree add --detach "$pair/proto" "$base"
for f in rtl/rng_lane.sv tb/tb_rng_lane.sv tb/tb_rng_stream.sv; do
  cp "$repo/$f" "$pair/proto/$f"
done
# Same default setup_fixed_v1 pair, corner, no retiming or external overrides.
unset LIB_DB LIB_LIB SDC PARAMS DESIGN RTL_FILES TAG REPORT_DIR CLK_PERIOD_NS
export RETIME=0 OPCOND=typical VCS=vcs DC_SHELL=dc_shell
command -v make bash vcs dc_shell
for f in constraints/lane_5ns.sdc scripts/syn/config.tcl scripts/syn/dc_synth.tcl \
         tech/gscl45nm/setup_fixed_v1/gscl45nm.lib \
         tech/gscl45nm/setup_fixed_v1/gscl45nm.db; do
  cmp "$pair/main/$f" "$pair/proto/$f"
done
for variant in main proto; do
  cd "$pair/$variant"
  make rng-test
  make rng-sim
  "$PYTHON" -B scripts/run_rng_validation.py \
    --tag "${run_id}_${variant}" --results-tag "${run_id}_${variant}" \
    --words 1048576 --streams 3
done
printf 'Matched run worktrees: %s\n' "$pair"
```

Do not pass `--skip-synth`: each invocation must reach the validation script's
DC step. It uses `lane_5ns.sdc`, a 5.0 ns period, and the shared DC flow, without
retiming. Each run checks three canonical RTL streams of 1,048,576 words plus
integration/bubble tests. Distinct random run tags preserve previous evidence.
The main worktree uses its unchanged testbenches; prototype uses the new invariant
checks. The synthesis scripts and settings are identical.

After both runs, compare these files under each worktree's
`reports/syn/${run_id}_${variant}/`:

- `inputs.txt`, `library_sha256.txt`, `source_sha256.txt`: confirm identical tool
  versions, corner, library, constraints, settings, and intended source changes.
- `summary.txt`: setup slack (`wns_ns`), `area_um2`, `registers`.
- `timing.rpt`: critical startpoints/endpoints, delay and top five paths.
- `violators.rpt`, `constraints.rpt`, `reset_timing.rpt`, `timing_check.rpt`:
  retain and enumerate hold, reset and electrical violations, even if setup passes.
- `results/${run_id}_${variant}_ppa.csv` and simulation manifests/logs: preserve
  alongside raw reports. A script PASS means validation completed, not signoff.

If either run fails, retain its partial logs, fix the cause and use fresh tags
for a new matched pair. Do not replace committed reference results. No P&R
command is part of this handoff.
