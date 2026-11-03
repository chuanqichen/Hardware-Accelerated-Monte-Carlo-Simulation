#!/bin/bash
# Re-run the block testbenches under VCS with tb/vcd_dump.sv attached and write
# one VCD per block into reports/waves/. scripts/plot_waves.py turns them into the
# documentation figures (docs/figures/wave_*.png). Run on peach from the repo
# root in a login shell with `module load syn/2022`.
set -euo pipefail
cd "$(dirname "$0")/../.."
OUT=${OUT:-reports/waves}
run_id=${MC_SIM_RUN_ID:-waves_$(date +%Y%m%d_%H%M%S)}
[[ "$run_id" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || { echo "Invalid MC_SIM_RUN_ID" >&2; exit 2; }
run_dir="$OUT/$run_id"
[[ ! -e "$run_dir" ]] || { echo "Run exists: $run_dir" >&2; exit 2; }
vcs_command=${VCS:-vcs}
command -v "$vcs_command" >/dev/null || { echo "VCS is missing" >&2; exit 2; }
mkdir -p "$OUT"
mkdir "$run_dir"
run_dir=$(cd "$run_dir" && pwd)
V=("$vcs_command" -sverilog -full64 -timescale=1ns/1ps -q -debug_access+all)

run_and_check() {
  local block=$1 marker=$2 log="$run_dir/$1.run.log"
  if ! "$run_dir/simv_$block" +vcd="$run_dir/$block.vcd" | tee "$log"; then
    echo "$block simulation failed: $log" >&2; return 1
  fi
  if grep -Eq '^(FAIL|ERROR|Error|FATAL|Fatal)(:|[[:space:]])' "$log" || ! grep -Eq "$marker" "$log"; then
    echo "$block did not reach a nonempty PASS: $log" >&2; return 1
  fi
  [[ -s "$run_dir/$block.vcd" ]] || { echo "Missing/empty $block VCD" >&2; return 1; }
}

echo "== gauss_lut (LATENCY=1)"
"${V[@]}" rtl/generated/gauss_lut_rom.sv rtl/gauss_lut.sv tb/tb_gauss_lut.sv tb/vcd_dump.sv \
  -pvalue+tb_gauss_lut.LATENCY=1 +define+VEC_FILE='"tb/vectors/gauss_lut_a10_w16_f12.hex"' \
  -Mdir="$run_dir/gauss_csrc" -o "$run_dir/simv_gauss_lut" -l "$run_dir/gauss_lut.compile.log" >/dev/null
run_and_check gauss_lut '^PASS: [1-9][0-9]* checked, 0 errors[[:space:]]*$'

echo "== rng_lane"
"${V[@]}" rtl/rng_lane.sv tb/tb_rng_lane.sv tb/vcd_dump.sv \
  -Mdir="$run_dir/rng_csrc" -o "$run_dir/simv_rng_lane" -l "$run_dir/rng_lane.compile.log" >/dev/null
run_and_check rng_lane '^PASS rng_lane: [1-9][0-9]* cycles, [1-9][0-9]* valid words[[:space:]]*$'

echo "== price_dp (MUL_STAGES=1)"
"${V[@]}" rtl/round_sat.sv rtl/pipe.sv rtl/generated/exp2_rom.sv rtl/exp2_unit.sv rtl/price_dp.sv \
  rtl/accumulator.sv tb/tb_price_dp.sv tb/vcd_dump.sv \
  -pvalue+tb_price_dp.MUL_STAGES=1 +define+VEC_FILE='"tb/vectors/price_dp_k10.hex"' \
  -Mdir="$run_dir/price_csrc" -o "$run_dir/simv_price_dp" -l "$run_dir/price_dp.compile.log" >/dev/null
run_and_check price_dp '^PASS: tb_price_dp k=10 MUL_STAGES=1 LAT_DP=6, [1-9][0-9]* trials checked, 0 errors[[:space:]]*$'

# Publish the plotting inputs only after all three checks succeed. Keep each run
# and its logs for diagnosis; never remove another runner's root csrc directory.
for block in gauss_lut rng_lane price_dp; do
  cp "$run_dir/$block.vcd" "$OUT/$block.vcd"
done
echo "PASS: waveform run $run_dir"
