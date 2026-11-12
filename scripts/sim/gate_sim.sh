#!/usr/bin/env bash
# Default one-lane mapped netlist, functional cell model, no SDF/timing claims.
set -euo pipefail
cd "$(dirname "$0")/../.."
vcs_command=${VCS:-vcs}
netlist=${NETLIST:?Set NETLIST to the mapped mc_top netlist}
cells=${CELL_MODEL:-/usr/local/packages/FreePDK45/osu_soc/lib/files/gscl45nm.v}
cases=${GATE_CASES:-tb/vectors/mc_top_cases.hex}
run_id=${MC_SIM_RUN_ID:-gate_$(date +%Y%m%d_%H%M%S)}
[[ "$run_id" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || { echo "Invalid MC_SIM_RUN_ID" >&2; exit 2; }
run_dir="$PWD/reports/sim/$run_id"
[[ ! -e "$run_dir" ]] || { echo "Run exists: $run_dir" >&2; exit 2; }
for path in "$netlist" "$cells" "$cases"; do
  [[ -s "$path" ]] || { echo "Missing/empty input: $path" >&2; exit 2; }
done
command -v "$vcs_command" >/dev/null || { echo "VCS missing" >&2; exit 2; }
mkdir -p "$run_dir"
sha256sum "$netlist" "$cells" "$cases" rtl/mc_pkg.sv tb/tb_mc_top_gate.sv "$0" > "$run_dir/source_sha256.txt"
"$vcs_command" -full64 -sverilog -timescale=1ns/1ps +notimingcheck +nospecify \
  rtl/mc_pkg.sv "$cells" "$netlist" tb/tb_mc_top_gate.sv -top tb_mc_top_gate \
  -Mdir="$run_dir/csrc" -o "$run_dir/simv" -l "$run_dir/compile.log"
"$run_dir/simv" "+cases=$cases" "+cycle_csv=$run_dir/cycles.csv" -l "$run_dir/run.log"
if grep -Eq '^(FAIL|ERROR|Error|FATAL|Fatal)(:|[[:space:]-])' "$run_dir/run.log" || \
   ! grep -q '^PASS: tb_mc_top_gate cases=22 trials=26457, exact results/status/cycles, zero-delay cells$' "$run_dir/run.log"; then
  echo "Mapped regression did not reach PASS: $run_dir/run.log" >&2; exit 1
fi
echo "Mapped functional regression complete: $run_dir"
