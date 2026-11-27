#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../.."
module load synopsys/2022 cadence/2022
export PYTHON=/home/work/teh969/pyenv/mc_py312/bin/python
unset LIB_DB LIB_LIB QRC_TECH SETUP_TARGET_SLACK_NS
tag=${ECO_TAG:?Set a fresh ECO_TAG}
lanes=${LANES:?Set LANES}
syn_batch=${SYN_BATCH:?Set SYN_BATCH}
[[ "$tag" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || exit 2
case "$lanes" in 1|2|4) ;; *) exit 2;; esac
log="reports/pnr/$tag.log"
[[ ! -e "$log" && ! -e "reports/pnr/$tag" ]] || { echo "Run exists: $tag" >&2; exit 2; }
status_file="build/tyler_rng_20261127/${tag}.exit"
trap 'rc=$?; printf "exit_code=%s\n" "$rc" > "$status_file"' EXIT
tool_status=0
innovus -no_gui -files reports/lab_artifacts/tyler_rngphysical_20261127/targeted_hold_eco_refill.tcl \
  > "$log" 2>&1 || tool_status=$?
if [[ "$tool_status" -ne 0 ]] || grep -Eq '^(\*\*ERROR|ERROR|Error|Fatal|FATAL|TARGETED_HOLD_ECO failed)[[:space:]]*:' "$log" || \
   ! grep -q "^PNR_DONE $tag " "$log"; then
  tail -40 "$log" >&2
  exit 1
fi
physical="$PWD/reports/pnr/$tag"
sim="$PWD/reports/sim/${tag}_routed"
LANES="$lanes" ACTIVITY=1 NETLIST="$physical/mc_top.routed.v" \
  GATE_CASES="$PWD/tmp/${syn_batch}_inputs/mc_array_l${lanes}_k10.hex" \
  MC_SIM_RUN_ID="${tag}_routed" bash scripts/sim/gate_array_sim.sh > "$physical/gate_runner.log" 2>&1
NETLIST="$physical/mc_top.routed.v" MAPPED_SDC="$physical/mc_top.routed.sdc" \
  SPEF="$physical/mc_top.routed.spef" VCD="$sim/activity.vcd" POWER_WINDOW="$sim/activity.txt" \
  STA_TAG="${tag}_routed_final" bash scripts/sta/prelayout.sh > "$physical/pt_runner.log" 2>&1
cat "reports/sta/${tag}_routed_final/summary.txt"
grep '^PASS:' "$sim/run.log"
echo "TARGETED_ECO_REPLAY_STA_DONE $tag"
