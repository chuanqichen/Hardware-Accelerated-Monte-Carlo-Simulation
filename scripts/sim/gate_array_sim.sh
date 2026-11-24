#!/usr/bin/env bash
# Replay the same interface corpus against each default a10/k10/G1/M1 mapping.
# Functional cell simulation only: no SDF or timing-equivalence claim.
set -euo pipefail
cd "$(dirname "$0")/../.."
lanes=${LANES:-1}
case "$lanes" in 1|2|4) ;; *) echo "LANES must be 1, 2 or 4" >&2; exit 2;; esac
activity=${ACTIVITY:-0}
case "$activity" in 0|1) ;; *) echo "ACTIVITY must be 0 or 1" >&2; exit 2;; esac
netlist=${NETLIST:?Set NETLIST to a mapped mc_top netlist}
cases=${GATE_CASES:?Set GATE_CASES to the matching mc_array corpus}
cells=${CELL_MODEL:-/usr/local/packages/FreePDK45/osu_soc/lib/files/gscl45nm.v}
vcs_command=${VCS:-vcs}
run_id=${MC_SIM_RUN_ID:-gate_array_l${lanes}_$(date +%Y%m%d_%H%M%S)}
[[ "$run_id" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || { echo "Invalid run id" >&2; exit 2; }
run_dir="$PWD/reports/sim/$run_id"
[[ ! -e "$run_dir" ]] || { echo "Run exists: $run_dir" >&2; exit 2; }
for path in "$netlist" "$cases" "$cells"; do
  [[ -s "$path" ]] || { echo "Missing/empty input: $path" >&2; exit 2; }
done
command -v "$vcs_command" >/dev/null || { echo "VCS missing" >&2; exit 2; }
mkdir -p "$run_dir"
sha256sum "$netlist" "$cases" "$cells" rtl/mc_pkg.sv tb/tb_mc_array.sv "$0" > "$run_dir/source_sha256.txt"
vcs_options=(-full64 -sverilog -timescale=1ns/1ps +notimingcheck +nospecify)
if [[ "$activity" == 1 ]]; then vcs_options+=(-debug_access+all); fi
"$vcs_command" "${vcs_options[@]}" \
  +define+MAPPED_MC_TOP rtl/mc_pkg.sv "$cells" "$netlist" tb/tb_mc_array.sv \
  -top tb_mc_array -pvalue+tb_mc_array.LANES="$lanes" -pvalue+tb_mc_array.CLOCK_PERIOD_NS=5.0 \
  -Mdir="$run_dir/csrc" -o "$run_dir/simv" -l "$run_dir/compile.log"
sim_args=("+CASES=$cases" "+CYCLE_CSV=$run_dir/cycles.csv")
if [[ "$activity" == 1 ]]; then sim_args+=("+VCD=$run_dir/activity.vcd"); fi
"$run_dir/simv" "${sim_args[@]}" -l "$run_dir/run.log"
expected_cases=$((26 + (lanes > 1) + (lanes > 2)))
case $lanes in 1) trials=27492;; 2) trials=27495;; 4) trials=27502;; esac
if grep -Eq '^(FAIL|ERROR|Error|FATAL|Fatal)(:|[[:space:]-])' "$run_dir/run.log" || \
   ! grep -qx "PASS: tb_mc_array L=$lanes G=1 M=1 A=10 K=10 cases=$expected_cases trials=$trials" "$run_dir/run.log"; then
  echo "Mapped array regression did not complete: $run_dir/run.log" >&2; exit 1
fi
if [[ "$activity" == 1 ]]; then
  [[ -s "$run_dir/activity.vcd" ]] || { echo "No activity VCD" >&2; exit 1; }
  grep -q '^ACTIVITY_WINDOW ' "$run_dir/run.log" || { echo "No activity window" >&2; exit 1; }
  awk '/^ACTIVITY_WINDOW / {for (i=2;i<=NF;i++) print $i}' "$run_dir/run.log" > "$run_dir/activity.txt"
  sha256sum "$run_dir/activity.vcd" > "$run_dir/activity_sha256.txt"
fi
echo "GATE_ARRAY_DONE $run_id (zero-delay functional cells)"
