#!/usr/bin/env bash
set -euo pipefail
vcs_command=${VCS:-vcs}
command -v "$vcs_command" >/dev/null || { echo "VCS missing; load the lab Synopsys module." >&2; exit 2; }
run_id=${MC_SIM_RUN_ID:-bubbles_$(date +%Y%m%d_%H%M%S)}
[[ "$run_id" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || { echo "Invalid MC_SIM_RUN_ID" >&2; exit 2; }
run_dir="$PWD/reports/sim/$run_id"
[[ ! -e "$run_dir" ]] || { echo "Run exists: $run_dir" >&2; exit 2; }
mkdir -p "$run_dir"
sources=(rtl/mc_pkg.sv rtl/pipe.sv rtl/rng_lane.sv rtl/generated/gauss_lut_rom.sv
  rtl/gauss_lut.sv rtl/generated/exp2_rom.sv rtl/exp2_unit.sv rtl/price_dp.sv
  rtl/accumulator.sv rtl/mc_lane_array.sv tb/tb_mc_lane_bubbles.sv)
sha256sum "${sources[@]}" tb/vectors/mc_top_cases.hex tb/vectors/mc_top_trace.hex > "$run_dir/source_sha256.txt"
"$vcs_command" -full64 -sverilog -timescale=1ns/1ps "${sources[@]}" \
  -Mdir="$run_dir/csrc" -o "$run_dir/simv" -l "$run_dir/compile.log"
"$run_dir/simv" -l "$run_dir/run.log"
grep -q '^PASS: tb_mc_lane_bubbles 100 exact trials' "$run_dir/run.log" || {
  echo "Bubble regression did not reach PASS: $run_dir/run.log" >&2; exit 1;
}
