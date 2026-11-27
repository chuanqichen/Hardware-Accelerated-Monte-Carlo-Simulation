#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")" && pwd)
: "${PYTHON:?Set PYTHON to your own Python environment}"
export VCS=vcs DC_SHELL=dc_shell RETIME=0 OPCOND=typical
export MPLBACKEND=Agg MPLCONFIGDIR="$root/matplotlib"
export PYTHONDONTWRITEBYTECODE=1
unset LIB_DB LIB_LIB SDC PARAMS DESIGN RTL_FILES TAG REPORT_DIR CLK_PERIOD_NS
command -v make bash vcs dc_shell
"$PYTHON" - "$root" <<'PY'
import hashlib,json,sys
from pathlib import Path
root=Path(sys.argv[1])
m=json.loads((root/'BUNDLE_MANIFEST.json').read_text())
for name,expected in m['source_sha256'].items():
    p=root/name
    if not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest()!=expected:
        raise SystemExit('Bundle input hash mismatch: '+name)
print('PASS bundle input hashes:', len(m['source_sha256']))
PY
test ! -e "$root/proto1"
test ! -e "$root/proto2"
cp -a "$root/main" "$root/proto1"
cp -a "$root/main" "$root/proto2"
cp -a "$root/prototype1_patch/." "$root/proto1/"
cp -a "$root/prototype2_patch/." "$root/proto2/"
for variant in proto1 proto2; do
  for file in constraints/lane_5ns.sdc scripts/run_rng_validation.py scripts/syn/config.tcl scripts/syn/dc_synth.tcl tech/gscl45nm/setup_fixed_v1/gscl45nm.lib tech/gscl45nm/setup_fixed_v1/gscl45nm.db; do
    cmp "$root/main/$file" "$root/$variant/$file"
  done
done
mkdir "$root/terminal_logs"
run_id=$(basename "$root")
for variant in main proto1 proto2; do
  tag="${run_id}_${variant}"
  cd "$root/$variant"
  make rng-test 2>&1 | tee "$root/terminal_logs/${variant}_rng_test.log"
  "$PYTHON" -B scripts/run_rng_validation.py --tag "$tag" --results-tag "$tag" --words 1048576 --streams 3 2>&1 | tee "$root/terminal_logs/${variant}_validation.log"
  if [ "$variant" = proto2 ]; then
    grep -Fx 'PASS rng_t_adder: 4193 exact modular sums' "reports/sim/$tag/rng_sim.log"
  fi
  printf '\nSynthesis summary: %s\n' "$variant"
  cat "reports/syn/$tag/summary.txt"
  grep -E 'Startpoint:|Endpoint:|slack \(' "reports/syn/$tag/timing.rpt"
done
cd "$root"
items=(BUNDLE_MANIFEST.json run_comparison.sh RNG_T_Update_Experiment.md terminal_logs prototype1_patch prototype2_patch)
for variant in main proto1 proto2; do
  tag="${run_id}_${variant}"
  items+=("$variant/reports/syn/$tag" "$variant/reports/sim/$tag" "$variant"/results/"${tag}"_*)
done
tar --exclude='*/work' --exclude='*/csrc' --exclude='*/simv_stream*' --exclude='*.ddc' --exclude='*.svf' --exclude='*.hex' -czf "$root/rng_t_update_results.tar.gz" "${items[@]}"
echo "THREE RUNS COMPLETED: $root"
echo "DOWNLOAD: $root/rng_t_update_results.tar.gz"
