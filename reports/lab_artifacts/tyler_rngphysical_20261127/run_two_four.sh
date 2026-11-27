#!/usr/bin/env bash
set -euo pipefail
cd /home/work/teh969/mc_rngphysical_20261127
session=build/tyler_rng_20261127
trap 'rc=$?; printf "exit_code=%s\n" "$rc" > "$session/two_four.exit"' EXIT
module load synopsys/2022 cadence/2022
export PYTHON=/home/work/teh969/pyenv/mc_py312/bin/python
unset LIB_DB LIB_LIB QRC_TECH SETUP_TARGET_SLACK_NS
test "$(git rev-parse HEAD)" = 9a0dda5c6346ad10e775de4711cade2d7e52f9a3
test -z "$(git status --porcelain --untracked-files=no)"
grep -qx 'exit_code=0' "$session/one_lane.exit"
LANES_LIST='2 4' BATCH=tyler_rng_syn24_20261127 \
  bash scripts/syn/run_multilane_sweep.sh > "$session/syn_l24.log" 2>&1
LANES_LIST='2 4' SYN_BATCH=tyler_rng_syn24_20261127 PNR_BATCH=tyler_rng_closure_20261127 \
  HOLD_TARGET_SLACK_NS=0.08 PRESERVE_SYNTH_BUFFERS=1 CTS_MAX_FANOUT=16 FIX_FANOUT_LOAD=1 \
  bash scripts/pnr/run_multilane.sh > "$session/pnr_l24.log" 2>&1
printf 'TWO_FOUR_COMPLETE\n'
