#!/bin/bash
# Synthesise gauss_lut over the ADDR_BITS x OUT_WIDTH grid of the numerical
# tradeoff study (Gaussian work plan Phase B; decision D-4) and parse the results.
#
# Run on peach from the repo root, in a login shell:
#   module load syn/2022
#   export PYTHON=/home/work/cc83382/venv/bin/python
#   scripts/syn/run_sweep.sh [ADDR_BITS list] [OUT_WIDTH list] [LATENCY list]
# Defaults: "8 10 12" "12 16" "1"
#
# The ROM contents depend on ADDR_BITS/OUT_WIDTH, so each point regenerates the
# ROM into its own directory before synthesis (never into rtl/generated, which
# stays at the committed ADDR_BITS=10 baseline). Raw reports: reports/syn/<tag>/.
# Parsed table: results/gauss_lut_ppa.csv.
set -euo pipefail
cd "$(dirname "$0")/../.."

ADDR_LIST=${1:-"8 10 12"}
WIDTH_LIST=${2:-"12 16"}
LAT_LIST=${3:-"1"}
PYTHON=${PYTHON:-python3}
# Build products (DC work dirs are large) go to the local disk if it exists.
SCRATCH=${SCRATCH:-/home/work/$USER/syn_scratch}
mkdir -p "$SCRATCH" reports/syn results
BATCH=${BATCH:-sweep_$(date +%Y%m%d_%H%M%S)}
[[ "$BATCH" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || { echo "Invalid BATCH" >&2; exit 2; }

for a in $ADDR_LIST; do
  for w in $WIDTH_LIST; do
    for l in $LAT_LIST; do
      f=$((w - 4))                        # Q3.f: 3 integer bits + sign, rest fraction
      tag="${BATCH}_gauss_lut_a${a}_w${w}_l${l}"
      gen="$SCRATCH/$tag/generated"
      mkdir -p "$gen"
      echo "=== $tag ==="
      $PYTHON model/gauss_lut.py --export "$gen" --addr-bits "$a" --out-width "$w" --frac-bits "$f" >/dev/null
      DESIGN=gauss_lut \
      RTL_FILES="rtl/mc_pkg.sv $gen/gauss_lut_rom.sv rtl/gauss_lut.sv" \
      PARAMS="ADDR_BITS=$a,OUT_WIDTH=$w,FRAC_BITS=$f,LATENCY=$l" \
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

$PYTHON scripts/parse_reports.py --syn reports/syn --filter "${BATCH}_" --out "results/gauss_lut_ppa_${BATCH}.csv"
