#!/usr/bin/env bash
# Final VCS regression for the pricing blocks (accumulator, exp2_unit, price_dp) plus
# the integrated runners. Run from the repo root on the lab machine (login shell,
# `module load syn/2022`), or `make sim-pricing-final`.
#
#   VCS=vcs PYTHON=/home/work/cc83382/venv/bin/python bash scripts/sim/pricing_final.sh
#   MC_SIM_RUN_ID=<id>    run id (default pricing_final_<timestamp>); [A-Za-z0-9][A-Za-z0-9_.-]*
#
# Evidence goes to reports/sim/<run id>/, one subdirectory per run with compile.log
# and run.log; the build products (csrc, simv, simv.daidir) are deleted after each
# PASS. The integrated runners top_sim.sh, lane_bubbles_sim.sh, round_sat_sim.sh and, when
# present, array_sim.sh (real 1/2/4-lane array)
# are called unmodified as child processes with run ids <id>_top, <id>_bubbles and
# <id>_rs (siblings under reports/sim/).
#
# Nothing is written to rtl/generated or tb/vectors: the exp ROM and the price_dp /
# exp2 / stream vectors for k = 8 and 10 are generated into <run dir>/gen_k<k>/, and the k = 10
# ROM must be byte-identical to the committed rtl/generated/exp2_rom.sv. The
# exhaustive exp2_k*.hex files (~4 MB each) are deleted after a successful run.
#
# Fail closed: VCS can exit 0 after a $fatal, so a run counts only if its run.log
# contains the exact expected PASS line and no FAIL/ERROR/Fatal line.
set -euo pipefail
cd "$(dirname "$0")/../.."

vcs_command=${VCS:-vcs}
python_command=${PYTHON:-python3}
command -v "$vcs_command" >/dev/null || { echo "VCS missing; load the lab Synopsys module." >&2; exit 2; }
command -v "$python_command" >/dev/null || { echo "Python missing: $python_command" >&2; exit 2; }
run_id=${MC_SIM_RUN_ID:-pricing_final_$(date +%Y%m%d_%H%M%S)}
[[ "$run_id" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || { echo "Invalid MC_SIM_RUN_ID" >&2; exit 2; }
sim_root="$PWD/reports/sim"
run_dir="$sim_root/$run_id"
for d in "$run_dir" "$sim_root/${run_id}_top" "$sim_root/${run_id}_bubbles" "$sim_root/${run_id}_rs"; do
  [[ ! -e "$d" ]] || { echo "Run exists: $d" >&2; exit 2; }
done
mkdir -p "$sim_root"
mkdir "$run_dir"
export VCS="$vcs_command"

ACC_SRC=(rtl/accumulator.sv tb/tb_accumulator.sv)
PRICE_COMMON=(rtl/mc_pkg.sv rtl/round_sat.sv rtl/pipe.sv rtl/exp2_unit.sv rtl/price_dp.sv rtl/accumulator.sv)
static_sources=("${ACC_SRC[@]}" "${PRICE_COMMON[@]}" rtl/generated/exp2_rom.sv tb/tb_exp2_unit.sv
  tb/tb_price_dp.sv rtl/round_sat.sv tb/tb_round_sat.sv
  tb/vectors/accumulator_w64.hex tb/vectors/accumulator_w32.hex
  tb/vectors/accumulator_l2_w64.hex tb/vectors/accumulator_l2_w32.hex
  tb/vectors/accumulator_l4_w64.hex tb/vectors/accumulator_l4_w32.hex
  tb/vectors/round_sat_i34_o18_s14_s.hex tb/vectors/round_sat_i26_o16_s8_u.hex)
# The integrated runners hash their own sources into <id>_top/ _bubbles/ source_sha256.txt.
sha256sum "${static_sources[@]}" > "$run_dir/source_sha256.txt"

passed=0
summary=()
infos=()

# Delete build products (not logs) below a run directory.
clean_build() {
  find "$1" \( -name csrc -o -name simv -o -name simv.daidir \) -prune -exec rm -rf {} +
}

# run_case <name> <PASS regex> <vcs args...>: compile, simulate, require the PASS line.
run_case() {
  local name=$1 expect=$2 dir="$run_dir/$1" line
  shift 2
  mkdir -p "$dir"
  echo "== $name"
  "$vcs_command" -full64 -sverilog -timescale=1ns/1ps +lint=all,noVCDE "$@" \
    -Mdir="$dir/csrc" -o "$dir/simv" -l "$dir/compile.log" >/dev/null \
    || { echo "$name: compile failed: $dir/compile.log" >&2; exit 1; }
  "$dir/simv" -l "$dir/run.log" >/dev/null \
    || { echo "$name: simulation failed: $dir/run.log" >&2; exit 1; }
  if grep -Eq '^(FAIL|ERROR|Error|FATAL|Fatal)' "$dir/run.log" || ! grep -Eq "$expect" "$dir/run.log"; then
    echo "$name did not reach the expected PASS line: $dir/run.log" >&2
    exit 1
  fi
  line=$(grep -E -m1 "$expect" "$dir/run.log")
  summary+=("$name: $line")
  while IFS= read -r info; do infos+=("$name: $info"); done < <(grep -E '^INFO: ' "$dir/run.log" || true)
  echo "   $line"
  passed=$((passed + 1))
  clean_build "$dir"
}

# ---- 1. accumulator: LANES x SUM_WIDTH (vectors default from the parameters) -----------
for l in 1 2 4; do
  for w in 64 32; do
    run_case "acc_l${l}_w${w}" \
      "^PASS: tb_accumulator LANES=$l SUM_WIDTH=$w, [1-9][0-9]* cycles checked, 0 errors([[:space:]]|\$)" \
      "${ACC_SRC[@]}" -pvalue+tb_accumulator.LANES="$l" -pvalue+tb_accumulator.SUM_WIDTH="$w"
  done
done

# ---- per-k ROM and vectors, outside rtl/generated and tb/vectors -----------------------
for k in 8 10; do
  gen="$run_dir/gen_k$k"
  mkdir "$gen"
  "$python_command" model/price_dp.py --export "$gen" --exp-addr-bits "$k" > "$gen/gen.log"
  "$python_command" model/gen_price_vectors.py --exp-addr-bits "$k" --out "$gen" >> "$gen/gen.log"
  rm -f "$gen"/accumulator_*.hex          # duplicates of tb/vectors; the tracked files are used
  sha256sum "$gen/exp2_rom.sv" "$gen/price_dp_k$k.hex" "$gen/price_dp_stream_k$k.hex" "$gen/exp2_k$k.hex" \
    >> "$run_dir/source_sha256.txt"
done
cmp -s "$run_dir/gen_k10/exp2_rom.sv" rtl/generated/exp2_rom.sv \
  || { echo "Committed rtl/generated/exp2_rom.sv differs from the model's k=10 ROM ($run_dir/gen_k10/exp2_rom.sv)" >&2; exit 1; }
echo "committed exp2_rom.sv matches the model's k=10 ROM"

# ---- 2. exp2_unit, exhaustive -------------------------------------------------------------
for k in 8 10; do
  gen="$run_dir/gen_k$k"
  run_case "exp2_k${k}" \
    "^PASS: tb_exp2_unit k=$k, 262144 checked, 0 errors([,[:space:]]|\$)" \
    "$gen/exp2_rom.sv" rtl/exp2_unit.sv tb/tb_exp2_unit.sv \
    -pvalue+tb_exp2_unit.EXP_ADDR_BITS="$k" "+define+VEC_FILE=\"$gen/exp2_k$k.hex\""
done

# ---- 3. price_dp: EXP_ADDR_BITS x MUL_STAGES, gapped vectors and the NO_GAPS back-to-back stream -----
for k in 8 10; do
  gen="$run_dir/gen_k$k"
  for m in 1 2; do
    run_case "price_dp_k${k}_m${m}" \
      "^PASS: tb_price_dp k=$k MUL_STAGES=$m LAT_DP=$((m + 5)), 11449 trials checked, 0 errors[[:space:]]*\$" \
      rtl/mc_pkg.sv rtl/round_sat.sv rtl/pipe.sv "$gen/exp2_rom.sv" rtl/exp2_unit.sv rtl/price_dp.sv \
      rtl/accumulator.sv tb/tb_price_dp.sv \
      -pvalue+tb_price_dp.EXP_ADDR_BITS="$k" -pvalue+tb_price_dp.MUL_STAGES="$m" \
      "+define+VEC_FILE=\"$gen/price_dp_k$k.hex\""
    # one configuration, 8192 trials with z_valid high on every cycle (initiation interval 1)
    run_case "price_dp_stream_k${k}_m${m}" \
      "^PASS: tb_price_dp stream k=$k MUL_STAGES=$m LAT_DP=$((m + 5)), 8192 trials checked, 0 errors, 8192 consecutive p_valid cycles[[:space:]]*\$" \
      rtl/mc_pkg.sv rtl/round_sat.sv rtl/pipe.sv "$gen/exp2_rom.sv" rtl/exp2_unit.sv rtl/price_dp.sv \
      rtl/accumulator.sv tb/tb_price_dp.sv \
      -pvalue+tb_price_dp.EXP_ADDR_BITS="$k" -pvalue+tb_price_dp.MUL_STAGES="$m" \
      -pvalue+tb_price_dp.NO_GAPS=1 \
      "+define+VEC_FILE=\"$gen/price_dp_stream_k$k.hex\""
  done
done

# ---- 4. integrated runners, unmodified; each fails closed on its own ------------------------
# run_child <suffix> <script> <expected PASS count>
run_child() {
  local suffix=$1 script=$2 want=$3 child="$sim_root/${run_id}_$1" n
  echo "== $script (MC_SIM_RUN_ID=${run_id}_$suffix)"
  MC_SIM_RUN_ID="${run_id}_$suffix" bash "scripts/sim/$script" >/dev/null \
    || { echo "$script failed; see $child" >&2; exit 1; }
  # The child scripts only grep for PASS; also reject a Fatal/FAIL/ERROR line anywhere in their logs.
  if grep -rEq --include=run.log '^(FAIL|ERROR|Error|FATAL|Fatal)' "$child"; then
    echo "$script: FAIL/ERROR/Fatal line in a run.log under $child" >&2; exit 1
  fi
  n=0
  while IFS= read -r line; do
    summary+=("$suffix: $line"); n=$((n + 1))
  done < <(grep -rh --include=run.log '^PASS: ' "$child" | sort || true)
  [[ "$n" == "$want" ]] || { echo "$script: expected $want PASS lines, found $n in $child" >&2; exit 1; }
  passed=$((passed + n))
  clean_build "$child"
}
run_child top top_sim.sh 4
run_child bubbles lane_bubbles_sim.sh 1
# make sim-rs: VCS=$VCS RS_VEC_S=... RS_VEC_U=... (the tracked vectors, which are the script defaults)
run_child rs round_sat_sim.sh 2

# ---- 5. multi-lane array replay, when the final-integration runner is in the tree ------------
# array_sim.sh covers 24 real 1/2/4-lane configurations (k=10 and k=8), the registered
# accumulator tree at 2 and 4 lanes, and the k=8 detailed trace: 27 PASS lines.
if [[ -f scripts/sim/array_sim.sh && -f scripts/prepare_array_sim.py ]]; then
  array_inputs="$run_dir/array_inputs"
  "$python_command" scripts/prepare_array_sim.py --out "$array_inputs" > "$run_dir/array_inputs.log"
  export ARRAY_INPUTS="$array_inputs"
  run_child array array_sim.sh 27
  unset ARRAY_INPUTS
  rm -rf "$array_inputs"          # reproducible; the child run keeps the hashes of what it used
fi

# ---- exhaustive vectors are reproducible from the model; do not keep them ----------------
rm -f "$run_dir"/gen_k*/exp2_k*.hex

# ---- summary ---------------------------------------------------------------------------------
tool_version=$(grep -h -m1 -E 'Version [A-Z]-[0-9]{4}' "$run_dir"/acc_l1_w64/compile.log 2>/dev/null || true)
[[ -n "$tool_version" ]] || tool_version=$( { "$vcs_command" -ID 2>&1 || true; } | head -n 3 | tr '\n' ' ' || true)
[[ -n "$tool_version" ]] || tool_version="unavailable"
git_rev=$(git rev-parse HEAD 2>/dev/null || true)
[[ -n "$git_rev" ]] || git_rev="not a git repository"
{
  echo "run_id: $run_id"
  echo "date: $(date)"
  echo "hostname: $(hostname 2>/dev/null || echo unknown)"
  echo "tool: $tool_version"
  echo "git: $git_rev"
  echo "runs passed: $passed"
  printf '%s\n' "${summary[@]}"
  [[ ${#infos[@]} -eq 0 ]] || printf '%s\n' "${infos[@]}"
} > "$run_dir/summary.txt"
echo "Pricing final regression complete: $run_dir ($passed runs passed)"
