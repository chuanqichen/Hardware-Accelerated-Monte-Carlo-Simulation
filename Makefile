# Single entry point for the things that can be run from the repo root.
#   make test   - Python model unit tests
#   make gen    - regenerate ROM RTL + testbench vectors from the model
#   make sim    - run tb_gauss_lut under VCS (lab machines)
#   make gen-price - regenerate exp ROM RTL + price_dp/exp/accumulator TB vectors
#   make sim-iv    - run tb_accumulator, tb_exp2_unit, tb_price_dp under Icarus (local)
#   make sim-price - the same three testbenches under VCS (lab machines)
#   make lint   - Verilator lint of the RTL (if installed)
#   make figures - regenerate docs/figures/*.png from scripts/make_figures.py
#   make docs   - build PDFs from docs/*.md with pandoc + xelatex
#   make clean  - remove tool outputs
#
# Gaussian LUT configuration (override: make gen ADDR_BITS=12)
ADDR_BITS ?= 10
OUT_WIDTH ?= 16
FRAC_BITS ?= 12
LATENCY   ?= 1

# Pricing datapath configuration (override: make sim-iv EXP_ADDR_BITS=8 MUL_STAGES=2)
EXP_ADDR_BITS ?= 10
MUL_STAGES    ?= 1

PYTHON ?= python3
IVERILOG ?= iverilog
VCS    ?= vcs
VERILATOR ?= verilator
PANDOC ?= pandoc

RTL     := rtl/generated/gauss_lut_rom.sv rtl/gauss_lut.sv
TB      := tb/tb_gauss_lut.sv
VEC     := tb/vectors/gauss_lut_a$(ADDR_BITS)_w$(OUT_WIDTH)_f$(FRAC_BITS).hex
PRICE_RTL := rtl/pipe.sv rtl/generated/exp2_rom.sv rtl/exp2_unit.sv rtl/price_dp.sv rtl/accumulator.sv
PRICE_VEC := tb/vectors/price_dp_k$(EXP_ADDR_BITS).hex tb/vectors/exp2_k$(EXP_ADDR_BITS).hex \
             tb/vectors/accumulator_w64.hex tb/vectors/accumulator_w32.hex
DOC_MD  := $(wildcard docs/*.md)
DOC_PDF := $(DOC_MD:.md=.pdf)

.PHONY: all test gen sweep sim lint figures docs clean gen-price sim-iv sim-price

all: test gen

test:
	cd model && $(PYTHON) -m unittest -v

sweep:
	$(PYTHON) model/gauss_lut.py

gen: rtl/generated/gauss_lut_rom.sv $(VEC)

rtl/generated/gauss_lut_rom.sv: model/gauss_lut.py model/fxp.py
	$(PYTHON) model/gauss_lut.py --export rtl/generated --addr-bits $(ADDR_BITS) --out-width $(OUT_WIDTH) --frac-bits $(FRAC_BITS)

$(VEC): model/gen_gauss_vectors.py model/gauss_lut.py model/fxp.py
	$(PYTHON) model/gen_gauss_vectors.py --addr-bits $(ADDR_BITS) --out-width $(OUT_WIDTH) --frac-bits $(FRAC_BITS)

sim: gen
	$(VCS) -sverilog -full64 -timescale=1ns/1ps $(RTL) $(TB) \
	  -pvalue+tb_gauss_lut.ADDR_BITS=$(ADDR_BITS) -pvalue+tb_gauss_lut.OUT_WIDTH=$(OUT_WIDTH) \
	  -pvalue+tb_gauss_lut.FRAC_BITS=$(FRAC_BITS) -pvalue+tb_gauss_lut.LATENCY=$(LATENCY) \
	  +define+VEC_FILE='"$(VEC)"' -o simv && ./simv

# ROM contents depend on EXP_ADDR_BITS, so always regenerate (it takes < 1 s).
gen-price:
	$(PYTHON) model/price_dp.py --export rtl/generated --exp-addr-bits $(EXP_ADDR_BITS)
	$(PYTHON) model/gen_price_vectors.py --exp-addr-bits $(EXP_ADDR_BITS)

IV := $(IVERILOG) -g2012 -o
sim-iv: gen-price
	@mkdir -p build
	$(IV) build/tb_acc64 rtl/accumulator.sv tb/tb_accumulator.sv
	vvp -n build/tb_acc64 | grep -E "^(PASS|FAIL|ERROR)"
	$(IV) build/tb_acc32 -Ptb_accumulator.SUM_WIDTH=32 -DVEC_FILE='"tb/vectors/accumulator_w32.hex"' \
	  rtl/accumulator.sv tb/tb_accumulator.sv
	vvp -n build/tb_acc32 | grep -E "^(PASS|FAIL|ERROR)"
	$(IV) build/tb_exp2 -Ptb_exp2_unit.EXP_ADDR_BITS=$(EXP_ADDR_BITS) \
	  -DVEC_FILE='"tb/vectors/exp2_k$(EXP_ADDR_BITS).hex"' \
	  rtl/generated/exp2_rom.sv rtl/exp2_unit.sv tb/tb_exp2_unit.sv
	vvp -n build/tb_exp2 | grep -E "^(PASS|FAIL|ERROR)"
	$(IV) build/tb_price_dp -Ptb_price_dp.EXP_ADDR_BITS=$(EXP_ADDR_BITS) -Ptb_price_dp.MUL_STAGES=$(MUL_STAGES) \
	  -DVEC_FILE='"tb/vectors/price_dp_k$(EXP_ADDR_BITS).hex"' $(PRICE_RTL) tb/tb_price_dp.sv
	vvp -n build/tb_price_dp | grep -E "^(PASS|FAIL|ERROR| )"

VCS_PRICE := $(VCS) -sverilog -full64 -timescale=1ns/1ps
sim-price: gen-price
	$(VCS_PRICE) rtl/accumulator.sv tb/tb_accumulator.sv -o simv_acc && ./simv_acc
	$(VCS_PRICE) rtl/generated/exp2_rom.sv rtl/exp2_unit.sv tb/tb_exp2_unit.sv \
	  -pvalue+tb_exp2_unit.EXP_ADDR_BITS=$(EXP_ADDR_BITS) \
	  +define+VEC_FILE='"tb/vectors/exp2_k$(EXP_ADDR_BITS).hex"' -o simv_exp && ./simv_exp
	$(VCS_PRICE) $(PRICE_RTL) tb/tb_price_dp.sv \
	  -pvalue+tb_price_dp.EXP_ADDR_BITS=$(EXP_ADDR_BITS) -pvalue+tb_price_dp.MUL_STAGES=$(MUL_STAGES) \
	  +define+VEC_FILE='"tb/vectors/price_dp_k$(EXP_ADDR_BITS).hex"' -o simv_pdp && ./simv_pdp

lint:
	$(VERILATOR) --lint-only -Wall -Irtl -Irtl/generated $(RTL) --top-module gauss_lut

figures: docs/figures/lane_block_diagram.png

docs/figures/lane_block_diagram.png: scripts/make_figures.py
	$(PYTHON) scripts/make_figures.py

docs: figures $(DOC_PDF)

docs/%.pdf: docs/%.md docs/figures/lane_block_diagram.png docs/templates/pdf-header.tex
	$(PANDOC) $< -o $@ --pdf-engine=xelatex --resource-path=docs \
	  -V mainfont="Helvetica Neue" -V monofont="Menlo" \
	  -V geometry:margin=0.8in -V fontsize=10pt -V colorlinks=true \
	  --shift-heading-level-by=-1 -H docs/templates/pdf-header.tex --metadata date="$(shell date +%Y-%m-%d)"

clean:
	rm -rf build simv simv.daidir simv_* csrc ucli.key *.log *.vcd *.fsdb obj_dir DVEfiles
