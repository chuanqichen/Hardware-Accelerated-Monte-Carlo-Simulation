#!/usr/bin/env bash
# VCS may return zero after $fatal; only a nonempty final PASS is success.
set -euo pipefail
vcs_command=${VCS:-vcs}
run_id=${MC_SIM_RUN_ID:-round_sat_$(date +%Y%m%d_%H%M%S)}
[[ "$run_id" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || { echo "Invalid MC_SIM_RUN_ID" >&2; exit 2; }
run_dir="$PWD/reports/sim/$run_id"
[[ ! -e "$run_dir" ]] || { echo "Run exists: $run_dir" >&2; exit 2; }
command -v "$vcs_command" >/dev/null || { echo "VCS is missing" >&2; exit 2; }
signed_vec=${RS_VEC_S:-tb/vectors/round_sat_i34_o18_s14_s.hex}
unsigned_vec=${RS_VEC_U:-tb/vectors/round_sat_i26_o16_s8_u.hex}
mkdir -p "$run_dir"
for signed in 1 0; do
  if [[ "$signed" == 1 ]]; then iw=34; ow=18; shift=14; vectors=$signed_vec
  else iw=26; ow=16; shift=8; vectors=$unsigned_vec; fi
  [[ -s "$vectors" ]] || { echo "Missing/empty vectors: $vectors" >&2; exit 1; }
  config_dir="$run_dir/signed_$signed"
  mkdir -p "$config_dir"
  "$vcs_command" -full64 -sverilog -timescale=1ns/1ps +lint=all,noVCDE \
    rtl/round_sat.sv tb/tb_round_sat.sv \
    -pvalue+tb_round_sat.IN_WIDTH="$iw" -pvalue+tb_round_sat.OUT_WIDTH="$ow" \
    -pvalue+tb_round_sat.SHIFT="$shift" -pvalue+tb_round_sat.SIGNED="$signed" \
    "+define+VEC_FILE=\"$vectors\"" -Mdir="$config_dir/csrc" -o "$config_dir/simv" -l "$config_dir/compile.log"
  "$config_dir/simv" -l "$config_dir/run.log"
  grep -Eq "^PASS: tb_round_sat IN=$iw OUT=$ow SHIFT=$shift SIGNED=$signed, [1-9][0-9]* checked, 0 errors " "$config_dir/run.log" || {
    echo "round_sat did not reach a nonempty PASS: $config_dir/run.log" >&2; exit 1;
  }
done
