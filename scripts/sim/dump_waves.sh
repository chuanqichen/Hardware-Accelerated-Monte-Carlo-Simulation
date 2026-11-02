#!/bin/bash
# Re-run the block testbenches under VCS with tb/vcd_dump.sv attached and write
# one VCD per block into reports/waves/. scripts/plot_waves.py turns them into the
# documentation figures (docs/figures/wave_*.png). Run on peach from the repo
# root in a login shell with `module load syn/2022`.
set -euo pipefail
cd "$(dirname "$0")/../.."
OUT=${OUT:-reports/waves}
mkdir -p "$OUT"
V="vcs -sverilog -full64 -timescale=1ns/1ps -q -debug_access+all"

echo "== gauss_lut (LATENCY=1)"
$V rtl/generated/gauss_lut_rom.sv rtl/gauss_lut.sv tb/tb_gauss_lut.sv tb/vcd_dump.sv \
  -pvalue+tb_gauss_lut.LATENCY=1 +define+VEC_FILE='"tb/vectors/gauss_lut_a10_w16_f12.hex"' \
  -o simv_w_gauss >/dev/null
./simv_w_gauss +vcd="$OUT/gauss_lut.vcd" | grep -E "^(PASS|FAIL)"

echo "== rng_lane"
$V rtl/rng_lane.sv tb/tb_rng_lane.sv tb/vcd_dump.sv -o simv_w_rng >/dev/null
./simv_w_rng +vcd="$OUT/rng_lane.vcd" | grep -E "^(PASS|FAIL)"

echo "== price_dp (MUL_STAGES=1)"
$V rtl/round_sat.sv rtl/pipe.sv rtl/generated/exp2_rom.sv rtl/exp2_unit.sv rtl/price_dp.sv \
  rtl/accumulator.sv tb/tb_price_dp.sv tb/vcd_dump.sv \
  -pvalue+tb_price_dp.MUL_STAGES=1 +define+VEC_FILE='"tb/vectors/price_dp_k10.hex"' \
  -o simv_w_price >/dev/null
./simv_w_price +vcd="$OUT/price_dp.vcd" | grep -E "^(PASS|FAIL)"

ls -la "$OUT"
rm -rf simv_w_* csrc ucli.key
