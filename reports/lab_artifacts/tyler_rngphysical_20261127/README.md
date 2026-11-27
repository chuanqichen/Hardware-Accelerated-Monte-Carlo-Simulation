# RNG physical-validation evidence

Source candidate: PR #27, `9a0dda5c6346ad10e775de4711cade2d7e52f9a3`.
Base main: `f137a6cfff27f0a19ab8878268a192df1af88f7d`.
Owner: Tyler Haverlah. Lab root:
`mario:/home/work/teh969/mc_rngphysical_20261127`.

See [the validation report](../../../docs/RNG_Physical_Validation.md) for results,
acceptance and limitations, and
[the run matrix](../../multilane_rng_lookahead_runs.csv) for exact run tags.
The archived `tyler_closure2_20261123` results remain the comparison baseline.
No library, constraint, RTL or shared-flow file was edited by this follow-up.

## Reproduction

Use an isolated checkout, your own lab account and a Python environment with the
project's existing NumPy/matplotlib dependencies. On mario the existing environment
is `/home/work/teh969/pyenv/mc_py312/bin/python`. Load `synopsys/2022 cadence/2022`
in a login shell. Keep all EDA output on owned lab scratch.

The executed runners are archived here as an execution record. They deliberately
pin HEAD and the owned lab path. To repeat exactly, use a fresh checkout of the
candidate, copy the runners into `build/tyler_rng_20261127/`, and adjust the owned
checkout path before running. Choose fresh tags rather than overwriting results.
The shared flow rejects existing output tags.

The flow entry points are:

```bash
make library-check test flow-test
make rng-sim
$PYTHON scripts/prepare_array_sim.py --out tmp/<fresh_rtl_inputs>
ARRAY_INPUTS=tmp/<fresh_rtl_inputs> MC_SIM_RUN_ID=<fresh_rtl_tag> \
  bash scripts/sim/array_sim.sh
LANES_LIST="1 2 4" BATCH=<fresh_syn_batch> \
  bash scripts/syn/run_multilane_sweep.sh
LANES_LIST="1 2 4" SYN_BATCH=<fresh_syn_batch> PNR_BATCH=<fresh_pnr_batch> \
  HOLD_TARGET_SLACK_NS=0.08 PRESERVE_SYNTH_BUFFERS=1 CTS_MAX_FANOUT=16 FIX_FANOUT_LOAD=1 \
  bash scripts/pnr/run_multilane.sh
```

Leave `LIB_DB`, `LIB_LIB`, `QRC_TECH` and `SETUP_TARGET_SLACK_NS` unset to reproduce
the recorded pair and policy. The executed matrix ran one lane first and reviewed
its acceptance before synthesizing and implementing two and four lanes serially.

To verify the archived matrix without EDA tools:

```bash
python scripts/summarize_multilane.py \
  --manifest reports/multilane_rng_lookahead_runs.csv \
  --out results/multilane_rng_lookahead \
  --methods docs/RNG_Physical_Validation.md
python scripts/classify_violations.py \
  reports/sta/tyler_rng_closure_20261127_l*_routed_final/violators.rpt
python reports/lab_artifacts/tyler_rngphysical_20261127/review_acceptance.py \
  --out reports/rng_physical_acceptance_20261127.json
```

### Two-lane ECO

The final matrix uses the additional two-lane ECO below. The other rows use the
initial shared-flow layouts. This conditional repair is explicit in the methods;
the shared-flow-only matrix retains its two-lane hold failure.

```bash
PARENT_TAG=tyler_rng_closure_20261127_l2 \
ECO_TAG=tyler_rng_closure_20261127_l2_hold2 \
ECO_PINS=u_lanes/u_price/p_reg_20_/D LANES=2 SYN_BATCH=tyler_rng_syn24_20261127 \
  bash -l reports/lab_artifacts/tyler_rngphysical_20261127/run_hold_eco.sh
```

`targeted_hold_eco_refill.tcl` removes only `FILL` cells, inserts one `BUFX2`,
routes the ECO and refills. The functional netlist adds one buffer/wire and changes
one D-pin connection. The SDC differs only in its timestamp comment. The script
records the parent output/database hashes and writes a fresh child database.
The parent database hashes re-verify after both ECO trials and layout rendering.

The first trial, `l2_hold1`, is retained with `targeted_hold_eco.tcl` and
`run_hold_eco_v1.sh`. It passed timing/replay but failed geometry/connectivity
because it legalized the new cell without first removing the parent's fillers.
It is not accepted. The following command must exit 1, with only the two-lane
geometry/connectivity checks rejected:

```bash
python reports/lab_artifacts/tyler_rngphysical_20261127/review_acceptance.py \
  --manifest reports/multilane_rng_lookahead_rejected_eco_runs.csv \
  --out reports/rng_physical_negative_control_20261127.json
```

The acceptance checker also verifies the child's unchanged parent input policy,
the parent-output hash record, unchanged SDC commands and the executed ECO script
hash. The common collector separately checks both initial and final matrices.

### Source audit and figures

`audit_sources.py` checks all 132 source entries for each of main, prototype 1
and prototype 2 against Git, allowing only hash-verified LF/CRLF reconstruction.
`source_audit.txt` records its result. `checks.txt` and `rng.txt` retain the
independent model/flow/library and short RNG results.

`render_layouts.sh` restores the final three databases with the existing
`scripts/pnr/render.tcl`. The GIF exports are converted losslessly to PNG; pixel
dimensions and RGBA values are checked equal. No image content is modified.

## Retention

The compact archive retains source/library hashes, inputs, full text reports,
logs, mapped and routed netlists, SDCs and compressed routed DEF/SPEF. The existing
collector verifies uncompressed digests when reading `.gz` files.

Simulator builds, synthesis work/DDC/SVF, raw VCD, GDS and Innovus databases stay
on lab scratch. Output/activity digests tie them to the compact evidence. A table
regeneration validates the archived evidence; it does not rerun synthesis,
simulation, extraction or timing. Detailed report coverage and unresolved
zero-limit capacitance rows remain limitations.
