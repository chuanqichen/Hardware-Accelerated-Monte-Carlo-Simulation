#!/usr/bin/env bash
# Same 5 ns constraints, library and numeric defaults for complete 1/2/4-lane tops.
# Each mapped netlist feeds both PrimeTime and interface-only VCS replay.
set -euo pipefail
cd "$(dirname "$0")/../.."
batch=${BATCH:-multilane_$(date +%Y%m%d_%H%M%S)}
[[ "$batch" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || { echo "Invalid BATCH" >&2; exit 2; }
python_command=${PYTHON:-python3}
dc_command=${DC_SHELL:-dc_shell}
command -v "$dc_command" >/dev/null || { echo "Design Compiler missing" >&2; exit 2; }
lanes_list=${LANES_LIST:-"1 2 4"}
for lanes in $lanes_list; do
  case "$lanes" in 1|2|4) ;; *) echo "LANES_LIST supports 1, 2, 4" >&2; exit 2;; esac
done
inputs="$PWD/tmp/${batch}_inputs"
[[ ! -e "$inputs" ]] || { echo "Input directory exists: $inputs" >&2; exit 2; }
for lanes in $lanes_list; do
  tag="${batch}_l${lanes}"
  for path in "reports/syn/$tag" "reports/syn/$tag.log" "reports/sta/$tag" "reports/sta/$tag.log" "reports/sim/${tag}_mapped"; do
    [[ ! -e "$path" ]] || { echo "Run exists: $path" >&2; exit 2; }
  done
done
mkdir -p reports/syn
"$python_command" scripts/prepare_array_sim.py --out "$inputs"
sources=$(tr -d '\r' < rtl/mc_top.f | tr '\n' ' ')
for lanes in $lanes_list; do
  tag="${batch}_l${lanes}"
  DESIGN=mc_top PARAMS="LANES=$lanes,GAUSS_LATENCY=1,MUL_STAGES=1,GAUSS_ADDR_BITS=10,EXP_ADDR_BITS=10" \
    CLK_PERIOD_NS=5.0 RETIME=0 OPCOND=typical RTL_FILES="$sources" \
    SDC="$PWD/constraints/lane_5ns.sdc" TAG="$tag" REPORT_DIR="reports/syn/$tag" \
    "$dc_command" -f scripts/syn/dc_synth.tcl > "reports/syn/$tag.log" 2>&1
  log="reports/syn/$tag.log"
  if grep -Eq '^(Error|Fatal|ERROR|FATAL|Synthesis failed)(:|[[:space:]-])' "$log" || \
     ! grep -q "^SYNTH_DONE $tag " "$log"; then
    echo "Synthesis did not complete: $log" >&2; exit 1
  fi
  cp "$log" "reports/syn/$tag/dc.log.txt"
  netlist="$PWD/reports/syn/$tag/mc_top.mapped.v"
  NETLIST="$netlist" MAPPED_SDC="$PWD/reports/syn/$tag/mc_top.mapped.sdc" STA_TAG="$tag" \
    bash scripts/sta/prelayout.sh > "reports/syn/$tag/pt_runner.log" 2>&1
  LANES="$lanes" NETLIST="$netlist" GATE_CASES="$inputs/mc_array_l${lanes}_k10.hex" \
    MC_SIM_RUN_ID="${tag}_mapped" bash scripts/sim/gate_array_sim.sh > "reports/syn/$tag/gate_runner.log" 2>&1
  grep "^SYNTH_DONE" "$log"
  cat "reports/sta/$tag/summary.txt"
  grep "^PASS:" "reports/sim/${tag}_mapped/run.log"
done
echo "MULTILANE_DONE $batch"
