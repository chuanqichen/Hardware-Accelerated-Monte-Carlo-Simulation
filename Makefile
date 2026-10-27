# Single entry point for the things that can be run from the repo root.
#   make test   - Python model unit tests
#   make gen    - regenerate ROM RTL + testbench vectors from the model
#   make sim    - run tb_gauss_lut under VCS (lab machines)
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

PYTHON ?= python3
VCS    ?= vcs
VERILATOR ?= verilator
PANDOC ?= pandoc

RTL     := rtl/generated/gauss_lut_rom.sv rtl/gauss_lut.sv
TB      := tb/tb_gauss_lut.sv
VEC     := tb/vectors/gauss_lut_a$(ADDR_BITS)_w$(OUT_WIDTH)_f$(FRAC_BITS).hex
DOC_MD  := $(wildcard docs/*.md)
DOC_PDF := $(DOC_MD:.md=.pdf)

.PHONY: all test gen sweep sim lint figures docs clean

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
	rm -rf simv simv.daidir csrc ucli.key *.log *.vcd *.fsdb obj_dir DVEfiles
