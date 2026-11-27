#!/usr/bin/env bash
set -euo pipefail
cd /home/work/teh969/mc_rngphysical_20261127
session=build/tyler_rng_20261127
trap 'rc=$?; printf "exit_code=%s\n" "$rc" > "$session/one_lane.exit"' EXIT
module load synopsys/2022 cadence/2022
export PYTHON=/home/work/teh969/pyenv/mc_py312/bin/python
unset LIB_DB LIB_LIB QRC_TECH SETUP_TARGET_SLACK_NS
test "$(git rev-parse HEAD)" = 9a0dda5c6346ad10e775de4711cade2d7e52f9a3
test -z "$(git status --porcelain --untracked-files=no)"
git rev-parse HEAD > "$session/source_commit.txt"
sha256sum rtl/rng_lane.sv constraints/lane_5ns.sdc tech/gscl45nm/setup_fixed_v1/gscl45nm.{lib,db} > "$session/input_sha256.txt"
make library-check test flow-test > "$session/checks.log" 2>&1
make rng-sim > "$session/rng.log" 2>&1
grep -q '^PASS rng_t_adder: 4193 exact modular sums' "$session/rng.log"
grep -q '^PASS rng_lane: 4440 cycles, 1763 valid words' "$session/rng.log"
"$PYTHON" scripts/prepare_array_sim.py --out tmp/tyler_rng_20261127_rtl_inputs > "$session/prepare_rtl.log" 2>&1
ARRAY_INPUTS=tmp/tyler_rng_20261127_rtl_inputs MC_SIM_RUN_ID=tyler_rng_20261127_rtl \
  bash scripts/sim/array_sim.sh > "$session/array.log" 2>&1
grep -q '^ARRAY_DONE tyler_rng_20261127_rtl' "$session/array.log"
test -z "$(git status --porcelain --untracked-files=no)"
LANES_LIST=1 BATCH=tyler_rng_syn_20261127 \
  bash scripts/syn/run_multilane_sweep.sh > "$session/syn_l1.log" 2>&1
LANES_LIST=1 SYN_BATCH=tyler_rng_syn_20261127 PNR_BATCH=tyler_rng_closure_20261127 \
  HOLD_TARGET_SLACK_NS=0.08 PRESERVE_SYNTH_BUFFERS=1 CTS_MAX_FANOUT=16 FIX_FANOUT_LOAD=1 \
  bash scripts/pnr/run_multilane.sh > "$session/pnr_l1.log" 2>&1
printf 'ONE_LANE_COMPLETE\n'
