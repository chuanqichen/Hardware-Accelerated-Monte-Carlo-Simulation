#!/bin/bash
# Synthesise the whole one-lane mc_top at each Gaussian table size of the numerical
# tradeoff study (weekly-plan configs D / A / E = GAUSS_ADDR_BITS 8 / 10 / 12) with the
# shared flow and constraints, so lane area, timing and power can be plotted against
# the exact price bias of the same table (scripts/plot_accuracy_vs_area.py).
#
# Run on peach from the repo root, in a login shell:
#   module load syn/2022
#   export PYTHON=/home/work/cc83382/venv/bin/python
#   scripts/syn/run_lane_sweep.sh [GAUSS_ADDR_BITS list] [EXP_ADDR_BITS]
# Defaults: "8 10 12" 10. Each point regenerates the Gaussian ROM into its own
# directory and substitutes it for rtl/generated/gauss_lut_rom.sv in rtl/mc_top.f;
# the committed baseline ROM is never touched. ~10 min per point.
set -euo pipefail
cd "$(dirname "$0")/../.."

ADDR_LIST=${1:-"8 10 12"}
EXP_BITS=${2:-10}
PYTHON=${PYTHON:-python3}
SCRATCH=${SCRATCH:-/home/work/$USER/syn_scratch}
BATCH=${BATCH:-lane_$(date +%Y%m%d_%H%M%S)}
[[ "$BATCH" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || { echo "Invalid BATCH" >&2; exit 2; }
mkdir -p "$SCRATCH" reports/syn results

for a in $ADDR_LIST; do
  tag="${BATCH}_mc_top_a${a}_k${EXP_BITS}"
  gen="$SCRATCH/$tag/generated"
  mkdir -p "$gen"
  echo "=== $tag ==="
  $PYTHON model/gauss_lut.py --export "$gen" --addr-bits "$a" --out-width 16 --frac-bits 12 >/dev/null
  if [ "$EXP_BITS" != 10 ]; then
    $PYTHON model/price_dp.py --export "$gen" --exp-addr-bits "$EXP_BITS" >/dev/null
    exp_rom="$gen/exp2_rom.sv"
  else
    exp_rom="rtl/generated/exp2_rom.sv"
  fi
  # mc_top.f with the two generated ROMs swapped for this configuration's tables.
  files=$(sed -e "s#^rtl/generated/gauss_lut_rom.sv\$#$gen/gauss_lut_rom.sv#" \
              -e "s#^rtl/generated/exp2_rom.sv\$#$exp_rom#" rtl/mc_top.f | tr '\n' ' ')
  DESIGN=mc_top \
  RTL_FILES="$files" \
  PARAMS="GAUSS_ADDR_BITS=$a,EXP_ADDR_BITS=$EXP_BITS,LANES=1,GAUSS_LATENCY=1,MUL_STAGES=1" \
  TAG="$tag" \
  REPORT_DIR="reports/syn/$tag" \
    dc_shell -f scripts/syn/dc_synth.tcl > "$SCRATCH/$tag/dc.log" 2>&1 \
    || { echo "FAILED: see $SCRATCH/$tag/dc.log"; tail -20 "$SCRATCH/$tag/dc.log"; exit 1; }
  grep -E "SYNTH_DONE|Error" "$SCRATCH/$tag/dc.log" | tail -3
  cp "$SCRATCH/$tag/dc.log" "reports/syn/$tag/dc.log.txt"
done

$PYTHON scripts/parse_reports.py --syn reports/syn --filter "${BATCH}_mc_top" --out "results/lane_addr_bits_ppa.csv"
