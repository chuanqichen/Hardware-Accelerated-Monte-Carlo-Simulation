# scripts/

Tool-flow scripts. Convention: every script is runnable from the repo root and writes
only under `reports/` (raw, unedited tool output) or `results/` (canonical CSV/plots
parsed from reports). Numbers in the report come from `results/`, never typed by hand.

Planned contents (owner: Tyler for synth/P&R; block owners add their run configs):

- `syn/`  - Design Compiler scripts: `dc_synth.tcl`, per-config variable files
           (`LANES`, `ADDR_BITS`, ...), library/corner setup
- `pnr/`  - Innovus flow: floorplan, place, CTS, route, timing/power extraction
- `sim/`  - VCS run wrappers for the block and integrated testbenches
- `parse_reports.py` - turns `reports/**/*.rpt` into `results/*.csv`
- `plot_results.py`  - produces the report figures from `results/*.csv`

Constraints (`.sdc`) live in `constraints/`.


## Integrated one-lane flow

PR #4 supplies shared constants/rounding and the golden model; PR #5 supplies the
shared synthesis flow, reset synchronizer and Gaussian study. Both are merged.
The integrated top is one lane only. Control-only 2/4-lane tests use a mock.

```bash
python -m unittest discover -s model
python -m unittest discover -s scripts -p 'test_*.py'
make gen-top PYTHON=python3   # explicit corpus regeneration; no ROM changes
make sim-top                # real pipeline, four G/M latency configurations
make sim-lane-bubbles       # real adapter pause/resume
make control-sim            # artificial backend, controller masks only
make sim-rs                 # both rounding configurations; fails closed
```

The integration and rounding runners require nonempty final PASS markers because
VCS can return zero after a fatal. The sim-top/lane targets use existing vectors
and committed baseline ROMs; they do not run gen-price. Shell files use LF.
Select a fresh MC_SIM_RUN_ID for each run to retain earlier evidence. The local
setup tests use standard Python tkinter/Tcl without a graphical display or license.

Use Tyler's existing SSH-agent login to `teh969@mario.ece.utexas.edu`, UT VPN, and a
login Bash shell. Keep builds in an owned directory below
`/home/work/teh969/monte_carlo/`; shared home quota is full. On mario the module is
`synopsys/2022`; Chuanqi's peach setup uses `syn/2022`. Do not use a teammate's
account/key or modify another lab/project setup.

```bash
module load synopsys/2022
DESIGN=mc_top TAG=mc_top_run_001 dc_shell -f scripts/syn/dc_synth.tcl
python scripts/parse_reports.py --syn reports/syn --filter mc_top_run_001 \
  --out results/one_lane_shared_5ns.csv
```

The consolidated flow uses PR #5's DESIGN/RTL_FILES/PARAMS/TAG/SDC/LIB_DB interface.
It replaces the unpublished MC_* synthesis variables. DESIGN=mc_top reads the
production source list from rtl/mc_top.f; standalone gauss_lut and mc_controller
also have default source lists. Other designs require explicit RTL_FILES. Mock
and testbench sources are rejected. PARAMS is a comma-separated NAME=integer list;
production mc_top currently permits only LANES=1.

The default SDC is constraints/lane_5ns.sdc: 5 ns, 30% I/O budgets, 0.1 ns clock
uncertainty and transition, typical gscl45nm at 1.1 V/27 C. CLK_PERIOD_NS can override
the period explicitly; keep it fixed across comparisons. OPCOND defaults to typical.
LIB_DB defaults to the system FreePDK45 gscl45nm.db, identical to the course copy.
Time is ns and capacitance pF. Recovery/removal arcs are enabled and reset paths
are reported. Never blanket false-path rst_n. Retiming is not enabled.

Every run records input/source/library metadata and mapped netlist/SDC. It refuses
to overwrite an existing REPORT_DIR or TAG directory. Keep partial evidence on
failure, fix the cause, and choose a new tag. The parser retains hold/electrical
violations and labels unannotated power. Slack-derived fmax_mhz is an estimate
under the current fixed I/O budgets, not a measured maximum frequency. No wire
load, extracted routing, activity-based energy or physical signoff is implied.

The Gaussian sweep uses a unique BATCH prefix and isolated generated ROMs, stops
on a failed configuration, and writes a batch-specific CSV. The historical 10 ns
smoke CSV can be reproduced with scripts/parse_smoke_reports.py; that parser is
retained only for the older report format. Current comparisons use the shared flow.

Details and current limits: docs/Integration_Work_Plan.md. Raw simulator logs are
local/gitignored; committed validation summaries and manifests preserve the evidence.

## Accuracy plot and waveform evidence

```bash
python model/price_study.py --plot-only  # redraw from results/price_vs_bs.csv
python -m unittest discover -s scripts -p 'test_dump_waves.py'
MC_SIM_RUN_ID=waves_001 bash scripts/sim/dump_waves.sh  # lab login shell + VCS
python scripts/plot_waves.py
```

The accuracy plot shows deterministic bias and the 95% confidence interval of the
mean over all seed runs. Its coverage panel checks each run's interval against
the exact hardware expectation, not Black-Scholes. Per-trial variance is measured
in software; the current RTL exports sum/count and flags, not a squared-payoff
sum. The 1% criterion bounds deterministic bias on the option grid, not each
run's total error. Plot-only mode leaves the CSV unchanged.

The waveform runner requires each block's nonempty PASS marker, no reported
FAIL/ERROR/Fatal, successful execution, and a nonempty VCD. It retains build and
simulation logs under reports/waves/<run_id>/ and refuses an existing run ID.
Only after all three blocks pass does it replace reports/waves/{gauss_lut,
rng_lane,price_dp}.vcd for plotting. It preserves other builds and older waveforms
on failure. OUT and VCS can override the output directory and compiler executable.
