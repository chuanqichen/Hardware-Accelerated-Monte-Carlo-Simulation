#!/bin/bash
# Synthesise the accumulator for each LANES value and parse the results. For
# LANES > 1 the registered reduction tree is selected (REGISTER_TREE=1), as
# mc_lane_array does.
#
# Run on peach from the repo root, in a login shell:
#   module load syn/2022
#   export PYTHON=<python >= 3.9 with numpy>     # system python3 on peach is 3.6
#   scripts/syn/run_accumulator_sweep.sh [LANES list]
# Default: "1 2 4". CLK_PERIOD_NS (if set) is passed through to dc_synth.tcl.
#
# Raw reports: reports/syn/<tag>/.  Parsed table: results/accumulator_ppa_<BATCH>.csv.
set -euo pipefail
cd "$(dirname "$0")/../.."

LANES_LIST=${1:-"1 2 4"}
PYTHON=${PYTHON:-python3}
# Build products (DC work dirs are large) go to the local disk if it exists.
if [[ -z "${SCRATCH:-}" ]]; then
  if [[ -d "/misc/scratch/$USER" ]]; then
    SCRATCH=/misc/scratch/$USER/mc/syn_scratch
  else
    SCRATCH=/home/work/$USER/syn_scratch
  fi
fi
mkdir -p "$SCRATCH" reports/syn results
BATCH=${BATCH:-sweep_$(date +%Y%m%d_%H%M%S)}
[[ "$BATCH" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || { echo "Invalid BATCH" >&2; exit 2; }

for l in $LANES_LIST; do
  tag="${BATCH}_accumulator_l${l}"
  mkdir -p "$SCRATCH/$tag"
  echo "=== $tag ==="
  DESIGN=accumulator \
  RTL_FILES="rtl/accumulator.sv" \
  PARAMS="LANES=$l,REGISTER_TREE=$(( l > 1 ? 1 : 0 ))" \
  TAG="$tag" \
  REPORT_DIR="reports/syn/$tag" \
    dc_shell -f scripts/syn/dc_synth.tcl > "$SCRATCH/$tag/dc.log" 2>&1 \
    || { echo "FAILED: see $SCRATCH/$tag/dc.log"; tail -20 "$SCRATCH/$tag/dc.log"; exit 1; }
  grep -E "SYNTH_DONE|Error" "$SCRATCH/$tag/dc.log" | tail -3
  mkdir -p "reports/syn/$tag"
  cp "$SCRATCH/$tag/dc.log" "reports/syn/$tag/dc.log.txt"
done

$PYTHON scripts/parse_reports.py --syn reports/syn --filter "${BATCH}_accumulator_" --out "results/accumulator_ppa_${BATCH}.csv"
