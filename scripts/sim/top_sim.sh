#!/usr/bin/env bash
set -euo pipefail
vcs_command=${VCS:-vcs}
command -v "$vcs_command" >/dev/null || { echo "VCS missing; load the lab Synopsys module." >&2; exit 2; }
run_id=${MC_SIM_RUN_ID:-top_$(date +%Y%m%d_%H%M%S)}
[[ "$run_id" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || { echo "Invalid MC_SIM_RUN_ID" >&2; exit 2; }
run_dir="$PWD/reports/sim/$run_id"
[[ ! -e "$run_dir" ]] || { echo "Run exists: $run_dir" >&2; exit 2; }
mkdir -p "$run_dir"
sources=(rtl/mc_pkg.sv rtl/pipe.sv rtl/rng_lane.sv rtl/generated/gauss_lut_rom.sv
  rtl/gauss_lut.sv rtl/generated/exp2_rom.sv rtl/exp2_unit.sv rtl/price_dp.sv
  rtl/accumulator.sv rtl/mc_controller.sv rtl/mc_lane_array.sv rtl/mc_top.sv tb/tb_mc_top.sv)
sha256sum "${sources[@]}" tb/vectors/mc_top_cases.hex tb/vectors/mc_top_trace.hex > "$run_dir/source_sha256.txt"
for gauss in 1 2; do
  for mul in 1 2; do
    config_dir="$run_dir/g${gauss}_m${mul}"
    mkdir -p "$config_dir"
    "$vcs_command" -full64 -sverilog -timescale=1ns/1ps +lint=all,noVCDE "${sources[@]}" \
      -pvalue+tb_mc_top.GAUSS_LATENCY="$gauss" -pvalue+tb_mc_top.MUL_STAGES="$mul" \
      -Mdir="$config_dir/csrc" -o "$config_dir/simv" -l "$config_dir/compile.log"
    "$config_dir/simv" -l "$config_dir/run.log"
    grep -q "^PASS: tb_mc_top G=$gauss M=$mul cases=22 trials=26457," "$config_dir/run.log" || {
      echo "Integrated regression did not reach PASS: $config_dir/run.log" >&2; exit 1;
    }
  done
done
echo "Integrated one-lane regression complete: $run_dir"
