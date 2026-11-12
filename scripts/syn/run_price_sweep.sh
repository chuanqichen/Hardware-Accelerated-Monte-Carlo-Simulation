#!/bin/bash
# Synthesise price_dp over the EXP_ADDR_BITS x MUL_STAGES x RETIME grid of the
# pricing-datapath study and parse the results.
#
# Run on peach from the repo root, in a login shell:
#   module load syn/2022
#   export PYTHON=<python >= 3.9 with numpy>     # system python3 on peach is 3.6
#   scripts/syn/run_price_sweep.sh [MUL_STAGES list] [EXP_ADDR_BITS list] [RETIME list]
# Defaults: "1 2" "8 10 12" "0 1"
#
# The exp ROM contents depend on EXP_ADDR_BITS, so each point regenerates the ROM
# into its own directory before synthesis (never into rtl/generated, which stays
# at the committed EXP_ADDR_BITS=10 baseline). RETIME=1 adds -retime to
# compile_ultra (see scripts/syn/dc_synth.tcl). Raw reports: reports/syn/<tag>/.
# Parsed table: results/price_dp_ppa_<BATCH>.csv.
set -euo pipefail
cd "$(dirname "$0")/../.."

MUL_LIST=${1:-"1 2"}
ADDR_LIST=${2:-"8 10 12"}
RETIME_LIST=${3:-"0 1"}
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

for k in $ADDR_LIST; do
  for m in $MUL_LIST; do
    for r in $RETIME_LIST; do
      tag="${BATCH}_price_dp_k${k}_m${m}_r${r}"
      gen="$SCRATCH/$tag/generated"
      mkdir -p "$gen"
      echo "=== $tag ==="
      $PYTHON model/price_dp.py --export "$gen" --exp-addr-bits "$k" >/dev/null
      DESIGN=price_dp \
      RTL_FILES="rtl/mc_pkg.sv rtl/round_sat.sv rtl/pipe.sv $gen/exp2_rom.sv rtl/exp2_unit.sv rtl/price_dp.sv" \
      PARAMS="EXP_ADDR_BITS=$k,MUL_STAGES=$m" \
      RETIME="$r" \
      TAG="$tag" \
      REPORT_DIR="reports/syn/$tag" \
        dc_shell -f scripts/syn/dc_synth.tcl > "$SCRATCH/$tag/dc.log" 2>&1 \
        || { echo "FAILED: see $SCRATCH/$tag/dc.log"; tail -20 "$SCRATCH/$tag/dc.log"; exit 1; }
      grep -E "SYNTH_DONE|Error" "$SCRATCH/$tag/dc.log" | tail -3
      cp "$SCRATCH/$tag/dc.log" "reports/syn/$tag/dc.log.txt"
      # Keep the isolated work directory with this immutable run.
    done
  done
done

$PYTHON scripts/parse_reports.py --syn reports/syn --filter "${BATCH}_price_dp_" --out "results/price_dp_ppa_${BATCH}.csv"
