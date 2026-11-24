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
The original integration checkpoint below uses one lane. The production top now
supports real 1/2/4-lane configurations; `make sim-array` exercises those arrays.

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
production mc_top permits the verified bounded counts LANES=1, 2, or 4.

The default SDC is constraints/lane_5ns.sdc: 5 ns, 30% I/O budgets, 0.1 ns clock
uncertainty and transition, typical gscl45nm at 1.1 V/27 C. CLK_PERIOD_NS can override
the period explicitly; keep it fixed across comparisons. OPCOND defaults to typical.
LIB_DB defaults to the versioned `tech/gscl45nm/setup_fixed_v1/gscl45nm.db`;
Innovus uses its matching Liberty file. The original and corrected files,
reconstruction rule, license and compiler provenance are under
[`tech/gscl45nm`](../tech/gscl45nm/README.md). Normal runs need no manual library
setup or recompilation. `make library-check` verifies the checked-in pair.
Set `LIB_DB` and `LIB_LIB` explicitly for original-library control runs.
Both overrides are required together and must name existing files; a half
override fails before synthesis, STA or implementation starts.
Time is ns and capacitance pF. Recovery/removal arcs are enabled and reset paths
are reported. Never blanket false-path rst_n. Retiming is off unless RETIME=1 (adds
-retime to compile_ultra).

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

## Multi-lane synthesis, implementation and power

The complete flow and its measured limitations are documented in
[Multilane_Implementation.md](../docs/Multilane_Implementation.md).
The default comparison is a10/k10, G=1, M=1, no retiming, at the shared 5 ns target.
Use fresh batch names; runners retain partial evidence and reject overwrites.

```bash
# On peach, in an owned checkout under /home/work (login shell):
module load syn/2022 cadence/2022
export PYTHON=/home/work/cc83382/venv/bin/python  # use your own account's environment
BATCH=study_001 make synth-multilane
SYN_BATCH=study_001 PNR_BATCH=layout_001 make implement-multilane

# Locally, reproduce the committed result tables/plots without EDA tools:
python scripts/summarize_multilane.py --plot
```

`synth-multilane` maps the complete top at each lane count, runs PrimeTime on the
same netlist/SDC and replays the model corpus with functional cell models.
`implement-multilane` adds floorplanning, power wiring, placement, CTS, detailed
routing, geometry/connectivity checks, and V/SDC/DEF/SPEF/GDS/checkpoint exports.
It then repeats the functional replay and captures one 1000-trial VCD window for
PrimeTime power. `LANES_LIST` can select a subset of 1/2/4 for a fresh physical run.

The native extraction model has no characterized cap table in this installation.
`QRC_TECH` accepts a matching technology file when available; `LIB_LIB`, `TECH_LEF`,
`GDS_MAP` and `CELL_GDS_DIR` select the corresponding physical assets.
The timing runner accepts optional `SPEF`, `VCD` and `POWER_WINDOW` inputs. It
preserves the raw SDC and audits two design-selector syntax translations for PT;
all timing/electrical constraints are retained. Timing/DRC closure is reported
separately from successful tool execution.

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

## Mapped functional replay and independent pre-layout STA

Use the netlist and exported SDC from the same synthesis run. Load the lab module
in a login shell and choose fresh MC_SIM_RUN_ID / STA_TAG values. No cell models
or libraries should be copied into the repository.

```bash
DESIGN=mc_top TAG=mc_top_new dc_shell -f scripts/syn/dc_synth.tcl
NETLIST=reports/syn/mc_top_new/mc_top.mapped.v make sim-gate
NETLIST=reports/syn/mc_top_new/mc_top.mapped.v \
MAPPED_SDC=reports/syn/mc_top_new/mc_top.mapped.sdc make sta
make integration-figures PYTHON=python3  # from the committed interim cycle/PPA CSVs
```

sim-gate uses the library's functional Verilog model (CELL_MODEL override),
disables specify/timing checks, and compares the default one-lane netlist's
external results/status/cycles against the complete golden corpus. It does not
depend on RTL hierarchy. This is zero-delay simulation, with no SDF or formal
equivalence claim. GATE_CASES can select a deliberately corrupted corpus for a
negative check; NETLIST is required so a stale mapping is never silently selected.

sta uses PrimeTime, LIB_DB (the shared gscl45nm default) and the exported mapped
SDC. It retains setup/hold, electrical, reset and coverage reports. Its successful
exit means analysis completed without command errors; inspect slack and untested
checks before making any timing claim. PrimeTime can log errors and still exit
zero, so the wrapper also requires STA_DONE and rejects logged errors. Both tools
preserve failed runs; correct the issue and select a new tag rather than reusing
or deleting old evidence. This flow has ideal clocks and no extracted parasitics.

The November 11 run confirms mapped functionality but PrimeTime misses 5 ns by
0.200381 ns. Its result supersedes any implication that DC's barely positive
setup slack establishes independent timing closure. See docs/Integration_Work_Plan.md.

## Final-integration candidate: teammate lab replay

Use a separate checkout/worktree of `tyler/final-integration` and your own lab
account. Keep the checkout and builds on the large lab scratch disk, not the
2 GB home directory. The Python interpreter needs NumPy and the project's
existing Python environment. Chuanqi's peach setup uses `module load syn/2022`;
Tyler's mario setup uses `module load synopsys/2022`. Choose fresh input/run tags.
Allow roughly 30 minutes and a few GB of scratch for 27 serial VCS builds; actual
tool runtime may differ. No waveforms are requested. No PDK files are copied.

```bash
# In the isolated candidate checkout, login shell, lab module loaded:
export PYTHON=/path/to/your/existing/python
"$PYTHON" -m unittest discover -s model -p 'test_*.py'
"$PYTHON" scripts/prepare_array_sim.py --out tmp/array_inputs_001
MC_SIM_RUN_ID=baseline_001 bash scripts/sim/top_sim.sh
MC_SIM_RUN_ID=control_001 bash scripts/sim/control_sim.sh
MC_SIM_RUN_ID=bubbles_001 bash scripts/sim/lane_bubbles_sim.sh
ARRAY_INPUTS=tmp/array_inputs_001 MC_SIM_RUN_ID=array_001 bash scripts/sim/array_sim.sh
# Compact handoff: source manifests and logs, excluding generated binaries/csrc.
find reports/sim/{baseline_001,control_001,bubbles_001,array_001} -type f \
  \( -name '*.log' -o -name '*sha256.txt' \) -print0 | \
  tar --null -T - -czf reports/final_integration_vcs_001.tar.gz
```

Record `git rev-parse HEAD` with the returned archive. Keep failed runs and choose
new tags when retrying. `ARRAY_DONE array_001` requires all 24 real-array configurations,
both registered-tree benches and the k8 detailed trace test to reach their exact
nonempty PASS markers. A logged failure after PASS is rejected even at exit zero.
The per-configuration manifests hash the actual ROM and expectation file used.
The baseline 4-configuration trace regression additionally checks existing behavior.

Local preparation needs no EDA license:

```bash
python -m unittest discover -s model -p 'test_*.py'
python -m unittest discover -s scripts -p 'test_*.py'
python scripts/prepare_array_sim.py --out tmp/array_inputs_001
# Optional isolated static parser; no project runtime dependency is introduced.
python -m pip install --target tmp/rtl_parser pyslang==12.2.0
python scripts/check_array_elaboration.py --parser-dir tmp/rtl_parser --inputs tmp/array_inputs_001
```

The November 23 VCS replay passed all 35 configurations in this recipe; see
`reports/pr_review_validation_2026-11-23.txt`. The array runner also supports
macOS Bash 3.2. Static checks remain separate from simulation. Defaults stay
a10/k10 and the DC gate stays at one lane pending multi-lane mapping and constraint
checks. Preserve the failed and untested timing checks
in all comparisons; do not report conditional 200 MHz throughput as achieved.
