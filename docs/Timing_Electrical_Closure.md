# Timing and electrical closure on the corrected-library baseline

Date: 2026-11-23. Tyler Haverlah, on mario (`synopsys/2022`, `cadence/2022`).
Tools: Innovus v21.18-s099_1, PrimeTime T-2022.03-SP5, VCS T-2022.06.

This study starts from the PR #22 head (`80562b1`, stacked on PR #21). Every run
places and routes the committed `setupfix_v1_20261123` mapped netlists and SDCs with
the versioned `setup_fixed_v1` library pair. The 5 ns clock, a10/k10, G1/M1, no
retiming, typical 1.1 V / 27 C corner, 30% I/O budgets, 0.10 ns uncertainty and
clock transition, reset recovery/removal checks, `max_transition 0.30` and
`max_fanout 16` are unchanged. No SDC, RTL or library file is modified. Only the
Innovus implementation recipe changes, through opt-in environment variables whose
defaults reproduce the PR #22 flow.

## Baseline reproduction

The unchanged PR #22 flow on mario reproduces the archived one-lane result exactly:
routed PT setup +0.687440 ns, hold -0.025964 ns, 9.968 mW, the same 33 hold,
160 max-fanout and 4,607 max-capacitance rows, and a passing routed replay of
26 cases / 27,492 trials. The replay corpus was regenerated and matches the archived
SHA-256 for all three lane counts.

## Root causes

1. **Hold.** The worst routed hold paths are single-register recirculation loops
   (for example Q, INVX1, AOI22X1, D on the same flop) with identical launch and
   capture clock paths. About 0.14 ns of data delay fails against the 0.10 ns
   uncertainty, which applies to hold as well as setup, plus about 0.06 ns library
   hold time. CTS skew is not the driver for these paths. Innovus fixed hold to a
   zero target.
2. **Innovus and PT disagree on every cell delay.** Innovus reports about 10% more
   delay per stage than PT. On the common worst one-lane setup path the difference
   is about 0.6 ns. SI explains only about 40 ps of it: Innovus arrival is 4.886 ns
   with SI-aware delay calculation and 4.847 ns without it. gscl45nm delay tables
   start at 0.1 pF load and 0.06 ns input slew. On the PR #22 one-lane layout, the
   4,607 nets that PT lists under max capacitance have 10th to 90th percentile
   loads of 2.3 to 13.1 fF, and the median critical-path slew is 0.033 ns. Cell
   delays are therefore extrapolated far below the characterized range, and the two
   tools extrapolate differently without warning. PT is therefore optimistic for setup and pessimistic for hold
   relative to Innovus, by tens of ps on short paths. A small margin in either tool
   alone is not evidence of closure.
3. **Max fanout.** gscl45nm defines no `fanout_load` or `default_fanout_load`.
   Innovus sums library fanout loads and sees zero, so it cannot see the SDC limit;
   DC and PT count one per sink. `place_opt_design` starts with `deleteBufferTree`,
   which removed 1,434/1,966/3,302 DC buffers and inverters for 1/2/4 lanes in
   PR #22, and the rebuilt nets reach 67 to 69 sinks (74 in PR #21). CCOpt separately allows 100 sinks per clock
   driver by default. Pre-layout PT on the DC netlists reports no fanout violations.
4. **Max capacitance.** Seven gscl45nm output pins declare `max_capacitance : 0`:
   AOI21X1/Y, AOI22X1/Y, DFFSR/Q, NAND2X1/Y, NAND3X1/Y, NOR2X1/Y and TBUFX1/Y. Any
   connected load violates that limit, and buffering cannot remove it. Every
   pre-layout and routed `max_capacitance` row in PR #21, PR #22 and this study is
   on one of these pins. No pin with a positive limit violates.
5. **RC-004.** PT cannot build a linear driver model from the INVX1 driving-cell
   data for rising arcs on a few input ports (seven in the PR #22 one-lane run, for
   example `cfg_addr[0]` and `start`). These are I/O paths with more than 1 ns of
   setup and hold slack, and the warning remains.

`scripts/classify_violations.py` reproduces these counts from any PT violator
report. It keeps every row and reports zero-limit capacitance rows as their own class.

## Closure policy

| Variable | Value | Effect |
|---|---|---|
| `HOLD_TARGET_SLACK_NS` | 0.08 | Innovus fixes hold to +80 ps, covering the measured Innovus/PT hold gap of up to about 50 ps |
| `PRESERVE_SYNTH_BUFFERS` | 1 | `place_design -noPrePlaceOpt`, `optDesign -preCTS` and `setOptMode -deleteInst false` keep DC's fanout-compliant trees |
| `CTS_MAX_FANOUT` | 16 | CCOpt `max_fanout`, matching the SDC limit on clock nets |
| `FIX_FANOUT_LOAD` | 1 | Requests Innovus fanout repair; it has no effect with this library because fanout load is zero |

None of these settings changes a constraint, waives a path or edits a library value.
PT remains the independent check, and closure here means both tools pass.

## One-lane sequence

| Run | Policy | PT setup / hold (ns) | Innovus setup / hold (ns) | Hold rows | Fanout rows (clock) | Signal-cell area (um2) | Power (mW) |
|---|---|---:|---:|---:|---:|---:|---:|
| `tyler_repro` | PR #22 defaults | +0.687 / -0.026 | +0.082 / +0.001 | 33 | 160 (31) | 29,817.9 | 9.97 |
| `tyler_holdfix` | hold target 0.05 | +0.694 / -0.003 | +0.072 / +0.042 | 2 | 160 (31) | 30,613.4 | 10.1 |
| `tyler_closure` | + keep DC buffers, target 0.08 | +0.651 / +0.034 | +0.020 / +0.046 | 0 | 30 (27) | 32,737.4 | 10.4 |
| `tyler_closure2` | + CTS fanout 16, no deletion | +0.355 / +0.021 | +0.058 / +0.080 | 0 | 0 (0) | 33,571.8 | 10.8 |

Innovus numbers are post-route `timeDesign` WNS with SI-aware delay calculation.
All four layouts pass the available geometry and connectivity checks, reset
recovery/removal has no negative slack, and every routed replay passes.

## Matched 1/2/4-lane result

The [generated tables](../results/multilane_closure_v1.md) and
[CSV](../results/multilane_closure_v1.csv) come from `scripts/summarize_multilane.py`
with the [run manifest](../reports/multilane_closure_v1_runs.csv). The collector
verifies digests, corpora, SDC translations, power units, RC annotation and the
library pair. Pre-layout PT and the mapped replays were rerun on mario for this
matrix and reproduce PR #22's pre-layout slacks.

| Lanes | PT setup / hold (ns) | Innovus setup / hold (ns) | Hold rows | Fanout rows | Max-cap rows (all zero limit) | Signal-cell area (um2) | Power (mW) | Energy (pJ/trial) |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | +0.355 / +0.021 | +0.058 / +0.080 | 0 | 0 | 4,491 | 33,571.8 | 10.8 | 54.6 |
| 2 | +0.283 / +0.018 | +0.002 / +0.033 | 0 | 0 | 8,139 | 58,925.3 | 19.2 | 49.2 |
| 4 | +0.260 / +0.033 | -0.006 / +0.006 | 0 | 0 | 15,596 | 112,537.2 | 36.8 | 48.6 |

PT reports no hold, max-fanout or max-transition violations at any lane count.
Reset recovery/removal has no negative slack, no timing check is violated in the
coverage report, all three layouts pass geometry/connectivity, and the mapped and
routed replays pass 81 cases / 82,489 trials. Both tools pass for one and two lanes.
For four lanes, Innovus reports one setup path at -0.006 ns
(`g_lane_3__u_rng/s0_reg_5_` to `u_reg_31_`, next path +0.051 ns), where PT reports
+0.260 ns. This is the RNG add/rotate/add path that the setup-table investigation
already identified as an optimization candidate.

## Cost and interpretation

Against the PR #22 baseline (29,817.9 / 53,033.7 / 99,424.5 um2 and
9.97 / 17.8 / 33.1 mW), signal-cell area rises by 12.6% / 11.1% / 13.2% and power by
8% / 8% / 11%. Innovus adds 499 / 932 / 2,865 hold cells, and the kept DC buffer
trees and the 16-sink clock tree add the rest. The DC netlists, mapped area and
target-rate throughput are unchanged. Hold buffering exists because the 0.10 ns
uncertainty also applies to hold and the two timers disagree in this library
regime. A smaller hold target saves area but leaves less margin for that
disagreement: with a 0.05 ns target, one-lane PT hold was still -0.003 ns.

## Remaining limits and decisions

- The zero `max_capacitance` limits remain as reported violations. Treating them as
  "no limit", or adding approximated limits, would be another project library
  change and needs the same documented faculty approval as `setup_fixed_v1`.
- Timing margins are tool estimates in an extrapolated library regime, under native
  RC estimates, one typical corner and zero-delay activity. They do not establish
  signoff or a rated maximum frequency. A characterized library and RC model would be
  needed to quantify true margins.
- The policy adds area and power. Report PPA for the PR #22 baseline and for the
  closed implementation separately.

## Reproduction

The corpus generator needs NumPy. mario's Python 3.9 has none, so the corpus was
generated on the laptop and its SHA-256 checked against the archived replay
manifests before use.

```bash
module load synopsys/2022 cadence/2022   # syn/2022 is equivalent on peach
unset LIB_DB LIB_LIB QRC_TECH
python scripts/prepare_array_sim.py --out tmp/setupfix_v1_20261123_inputs
LANES_LIST="1 2 4" SYN_BATCH=setupfix_v1_20261123 PNR_BATCH=<fresh_tag> \
  HOLD_TARGET_SLACK_NS=0.08 PRESERVE_SYNTH_BUFFERS=1 CTS_MAX_FANOUT=16 FIX_FANOUT_LOAD=1 \
  make implement-multilane
for l in 1 2 4; do   # pre-layout PT and mapped replay on the same host
  syn="$PWD/reports/syn/setupfix_v1_20261123_l$l"
  NETLIST="$syn/mc_top.mapped.v" MAPPED_SDC="$syn/mc_top.mapped.sdc" \
    STA_TAG=<fresh_pre_tag>_l$l bash scripts/sta/prelayout.sh
  LANES=$l NETLIST="$syn/mc_top.mapped.v" MC_SIM_RUN_ID=<fresh_pre_tag>_l${l}_mapped \
    GATE_CASES="$PWD/tmp/setupfix_v1_20261123_inputs/mc_array_l${l}_k10.hex" \
    bash scripts/sim/gate_array_sim.sh
done
python scripts/summarize_multilane.py --manifest <manifest.csv> --out <results/name> \
  --methods docs/Timing_Electrical_Closure.md
python scripts/classify_violations.py reports/sta/<fresh_tag>_l*_routed_final/violators.rpt
```

`scripts/pnr/timing_diagnostics.tcl` re-times a saved routed database with SI-aware
delay calculation on and off and reports named endpoints for same-path comparison.
