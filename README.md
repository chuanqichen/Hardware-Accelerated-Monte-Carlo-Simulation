# Hardware Accelerated Monte Carlo Simulation

ECE 382M-7 VLSI I (Fall 2026) team project: a lane-parallel Monte Carlo European
call-option pricer in SystemVerilog with a bit-accurate Python reference.
Team: Tyler Haverlah, Chuanqi Chen, Eric Goode, Shentong Zhong.

## Layout

```
docs/            project documents (proposal, work plans, spec/design/user/test docs)
  course/        course handouts + example reports (local only, see its README)
  references/    literature notes, bibliography, citation validation
model/           Python golden model and test-vector generators
rtl/             synthesizable SystemVerilog
  generated/     produced by model/ scripts - never hand-edit
tb/              testbenches; tb/vectors/ holds generated vectors
scripts/         synthesis / P&R / sim / report-parsing scripts
constraints/     SDC timing constraints
reports/         raw tool reports (synthesis, timing, power, DRC/LVS)
results/         canonical CSVs and plots parsed from reports/
```

Start with `docs/Project_Proposal.md`; per-block plans are `docs/*_Work_Plan.md`.

## Quick start

```bash
make test     # Python model unit tests
make sweep    # Gaussian LUT accuracy/price-bias sweep
make gen      # regenerate ROM RTL + testbench vectors
make sim      # VCS: run tb_gauss_lut (lab machines)
make docs     # build PDFs from docs/*.md (pandoc + xelatex)
```
