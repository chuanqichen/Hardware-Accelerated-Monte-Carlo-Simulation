#!/usr/bin/env bash
# Prepare vectors/ROMs with prepare_array_sim.py on a current Python host first.
set -euo pipefail
cd "$(dirname "$0")/../.."
vcs_command=${VCS:-vcs}
command -v "$vcs_command" >/dev/null || { echo "VCS missing" >&2; exit 2; }
run_id=${MC_SIM_RUN_ID:-array_$(date +%Y%m%d_%H%M%S)}
[[ "$run_id" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || { echo "Invalid run id" >&2; exit 2; }
vectors=${ARRAY_INPUTS:?Set ARRAY_INPUTS to the prepare_array_sim.py output directory}
run_dir="$PWD/reports/sim/$run_id"
[[ ! -e "$run_dir" ]] || { echo "Run exists: $run_dir" >&2; exit 2; }
mkdir -p "$run_dir"
mapfile -t baseline < <(tr -d '\r' < rtl/mc_top.f)
require_pass() {
  local log=$1 pattern=$2
  if ! grep -Eq "$pattern" "$log" || grep -Eq '^(Error|Fatal|FATAL|FAIL)(:|-|[[:space:]])' "$log"; then
    echo "Simulation did not complete cleanly: $log" >&2; exit 1
  fi
}
sha256sum "${baseline[@]}" tb/tb_mc_array.sv tb/tb_accumulator_tree.sv tb/tb_mc_top.sv > "$run_dir/source_sha256.txt"
for exp_bits in 10 8; do
  sources=()
  for source in "${baseline[@]}"; do
    if [[ "$source" == rtl/generated/exp2_rom.sv && "$exp_bits" == 8 ]]; then
      source="$vectors/k8/exp2_rom.sv"
    fi
    sources+=("$source")
  done
  for lanes in 1 2 4; do
    cases="$vectors/mc_array_l${lanes}_k${exp_bits}.hex"
    [[ -s "$cases" ]] || { echo "Missing $cases" >&2; exit 2; }
    for gauss in 1 2; do
      for mul in 1 2; do
        config_dir="$run_dir/l${lanes}_k${exp_bits}_g${gauss}_m${mul}"
        mkdir "$config_dir"
        sha256sum "${sources[@]}" "$cases" > "$config_dir/source_sha256.txt"
        "$vcs_command" -full64 -sverilog -timescale=1ns/1ps "${sources[@]}" tb/tb_mc_array.sv \
          -top tb_mc_array -pvalue+tb_mc_array.LANES="$lanes" \
          -pvalue+tb_mc_array.GAUSS_LATENCY="$gauss" -pvalue+tb_mc_array.MUL_STAGES="$mul" \
          -pvalue+tb_mc_array.EXP_ADDR_BITS="$exp_bits" \
          -Mdir="$config_dir/csrc" -o "$config_dir/simv" -l "$config_dir/compile.log"
        "$config_dir/simv" +CASES="$cases" -l "$config_dir/run.log"
        expected_cases=$((26 + (lanes > 1) + (lanes > 2)))
        case $lanes in 1) expected_trials=27492;; 2) expected_trials=27495;; 4) expected_trials=27502;; esac
        require_pass "$config_dir/run.log" "^PASS: tb_mc_array L=$lanes G=$gauss M=$mul A=10 K=$exp_bits cases=$expected_cases trials=$expected_trials$"
      done
    done
  done
done
# Exhaust all masks and flush/overflow behavior independently of the price model.
for lanes in 2 4; do
  dir="$run_dir/tree_l$lanes"; mkdir "$dir"
  "$vcs_command" -full64 -sverilog -timescale=1ns/1ps rtl/accumulator.sv tb/tb_accumulator_tree.sv \
    -top tb_accumulator_tree -pvalue+tb_accumulator_tree.LANES="$lanes" \
    -Mdir="$dir/csrc" -o "$dir/simv" -l "$dir/compile.log"
  "$dir/simv" -l "$dir/run.log"
  require_pass "$dir/run.log" "^PASS: tb_accumulator_tree L=$lanes cycles=[1-9][0-9]*, masks bubbles clear overflow$"
done
# Detailed stage traces for the proposed k8 table, with matching generated ROM.
dir="$run_dir/k8_traces"; mkdir "$dir"
mapfile -t sources < <(tr -d '\r' < rtl/mc_top.f)
for i in "${!sources[@]}"; do
  [[ "${sources[$i]}" != rtl/generated/exp2_rom.sv ]] || sources[$i]="$vectors/k8/exp2_rom.sv"
done
"$vcs_command" -full64 -sverilog -timescale=1ns/1ps "${sources[@]}" tb/tb_mc_top.sv \
  -top tb_mc_top -pvalue+tb_mc_top.EXP_ADDR_BITS=8 \
  -Mdir="$dir/csrc" -o "$dir/simv" -l "$dir/compile.log"
"$dir/simv" +VECTOR_DIR="$vectors/k8" -l "$dir/run.log"
require_pass "$dir/run.log" '^PASS: tb_mc_top G=1 M=1 cases=22 trials=26457,'
echo "ARRAY_DONE $run_id"
