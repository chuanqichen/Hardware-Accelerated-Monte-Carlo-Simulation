#!/usr/bin/env bash
# Run from repo root. The mock proves control behavior only, never pricing.
set -euo pipefail
vcs_command=${VCS:-vcs}
command -v "$vcs_command" >/dev/null || { echo "VCS is missing; load the lab Synopsys environment." >&2; exit 2; }
run_id=${MC_SIM_RUN_ID:-control_$(date +%Y%m%d_%H%M%S)}
[[ "$run_id" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || { echo "Invalid MC_SIM_RUN_ID" >&2; exit 2; }
run_dir="$PWD/reports/sim/$run_id"
[[ ! -e "$run_dir" ]] || { echo "Run exists: $run_dir; use a new MC_SIM_RUN_ID." >&2; exit 2; }
mkdir -p "$run_dir"
for lanes in 1 2 4; do
  lane_dir="$run_dir/lanes_$lanes"
  mkdir -p "$lane_dir"
  "$vcs_command" -full64 -sverilog -timescale=1ns/1ps \
    rtl/mc_pkg.sv rtl/mc_controller.sv rtl/mc_top.sv tb/mocks/mc_lane_array.sv tb/tb_mc_control.sv \
    -pvalue+tb_mc_control.LANES="$lanes" \
    -Mdir="$lane_dir/csrc" -o "$lane_dir/simv" -l "$lane_dir/compile.log"
  "$lane_dir/simv" -l "$lane_dir/run.log"
  # This lab VCS can return zero after $fatal. Require the test's final marker.
  grep -q "^PASS: mc_top control shell LANES=$lanes, " "$lane_dir/run.log" || {
    echo "Control regression did not reach PASS: $lane_dir/run.log" >&2; exit 1;
  }
done
echo "Control-only regression complete: $run_dir"
