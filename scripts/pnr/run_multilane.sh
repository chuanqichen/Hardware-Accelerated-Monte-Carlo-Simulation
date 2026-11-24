#!/usr/bin/env bash
# Reproduce physical implementation, routed functional replay, and annotated PT.
# Load syn/2022 and cadence/2022; first run the matching synthesis batch.
set -euo pipefail
cd "$(dirname "$0")/../.."
syn_batch=${SYN_BATCH:?Set SYN_BATCH to the completed multi-lane synthesis batch}
pnr_batch=${PNR_BATCH:-physical_$(date +%Y%m%d_%H%M%S)}
for tag in "$syn_batch" "$pnr_batch"; do
  [[ "$tag" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || { echo "Invalid batch tag" >&2; exit 2; }
done
lanes_list=${LANES_LIST:-"1 2 4"}
for lanes in $lanes_list; do
  case "$lanes" in 1|2|4) ;; *) echo "LANES_LIST supports 1, 2, 4" >&2; exit 2;; esac
done
for lanes in $lanes_list; do
  tag="${pnr_batch}_l${lanes}"
  synth="$PWD/reports/syn/${syn_batch}_l${lanes}"
  physical="$PWD/reports/pnr/$tag"
  sim="$PWD/reports/sim/${tag}_routed"
  PNR_TAG="$tag" NETLIST="$synth/mc_top.mapped.v" MAPPED_SDC="$synth/mc_top.mapped.sdc" \
    bash scripts/pnr/implement.sh
  LANES="$lanes" ACTIVITY=1 NETLIST="$physical/mc_top.routed.v" \
    GATE_CASES="$PWD/tmp/${syn_batch}_inputs/mc_array_l${lanes}_k10.hex" \
    MC_SIM_RUN_ID="${tag}_routed" bash scripts/sim/gate_array_sim.sh > "$physical/gate_runner.log" 2>&1
  NETLIST="$physical/mc_top.routed.v" MAPPED_SDC="$physical/mc_top.routed.sdc" \
    SPEF="$physical/mc_top.routed.spef" VCD="$sim/activity.vcd" POWER_WINDOW="$sim/activity.txt" \
    STA_TAG="${tag}_routed_final" bash scripts/sta/prelayout.sh > "$physical/pt_runner.log" 2>&1
  cat "reports/sta/${tag}_routed_final/summary.txt"
  grep '^PASS:' "$sim/run.log"
done
echo "PHYSICAL_SWEEP_DONE $pnr_batch"
