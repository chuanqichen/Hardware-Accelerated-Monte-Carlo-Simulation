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

## Integrated one-lane validation

The top, controller and production lane adapter connect the merged block owners'
RTL. Run `make gen-top PYTHON=python3` deliberately to regenerate expectations,
then `make sim-top` and `make sim-lane-bubbles` on VCS. `make control-sim` uses a
separate artificial backend; only the production target establishes pricing results.

Shared synthesis: `DESIGN=mc_top TAG=mc_top_run_001 make synth-smoke` on the lab
server. The default common target is 5 ns, with explicit reset recovery/removal
checks. Current results still have hold/electrical violations and negligible setup
margin. See [integration work plan](docs/Integration_Work_Plan.md) and
[scripts](scripts/README.md) for requirements, evidence, and reproducible commands.
