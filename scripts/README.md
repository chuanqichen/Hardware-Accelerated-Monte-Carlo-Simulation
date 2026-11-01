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


## Integrated one-lane flow (Tyler, 2026-10-31)

This local branch is based on PR #4 head c6da2ad. Keep that prerequisite explicit
when publishing. The original Week 1 checkout and its evidence remain unchanged.

```bash
python -m unittest discover -s model -v
python -m unittest discover -s scripts -p 'test_*.py' -v
python model/gen_mc_top_vectors.py    # explicit: 22 cases and 26,457 trace rows
make sim-top                         # real pipeline, G/M latency 1/2 matrix
make sim-lane-bubbles                 # real pipeline pause/resume, G=2 M=2
make control-sim                     # artificial backend, controller masks only
```

Without make, use the matching `scripts/sim/*_sim.sh` with Bash. VCS and existing
baseline ROMs/vectors must be present; integrated sim targets do not regenerate
price/Gaussian ROMs. Each runner requires a final PASS marker because the lab VCS
can return zero after test failure. Choose a fresh MC_SIM_RUN_ID to retain evidence.
The setup/parser tests use standard Python tkinter/Tcl without a display or license.

Use the existing SSH-agent login to `teh969@mario.ece.utexas.edu` with UT VPN and a
login Bash shell. Keep source/build output in a separate owned directory below
`/home/work/teh969/monte_carlo/`, not the quota-limited shared home. Do not edit
another lab/project's setup or use a teammate's account/key from AGENTS.md.

```bash
module load synopsys/2022
export MC_TARGET_LIBS=/home/ecelrc/students/shm923/vlsi1_2026/lab2/gscl45nm.db
export MC_CORNER=typical
export MC_CLOCK_NS=10.0
export MC_TOP=mc_top
export MC_RUN_ID=top_run_001
export MC_SOURCE_REVISION="$(git rev-parse HEAD)"  # label; hashes capture dirty inputs
# make synth-smoke, or directly:
dc_shell -f scripts/syn/dc_synth.tcl
python scripts/parse_reports.py reports/syn/top_run_001 --out results/one_lane_synthesis.csv
```

The selected .db matches the system FreePDK45 copy; its operating condition is
process=1, voltage=1.1 V, temperature=27 C, typical. Time is ns and capacitance pF.
The flow requires real existing library paths and an actual operating-condition
name. No library/model files are copied. `MC_TOP` also accepts `mc_controller` and
`gauss_lut`. Full-top synthesis currently uses LANES=1, Gaussian/exp address bits
10, and default latencies. No production 2/4-lane or retiming sweep is claimed.

Outputs and source/library hashes go to `reports/syn/<run>/`. The flow refuses to
overwrite a prior run. Preserve partial evidence on failure, correct the reported
problem, and use a fresh run ID. The CSV preserves timing/electrical violations.
Review units, operating conditions, mapping/black boxes, constraints and slack.
Ideal-clock synthesis with no wire load is not routed timing or power signoff.

Current contracts and resume point: `docs/Integration_Work_Plan.md`. Raw final logs
are gitignored; keep or deliberately export them with any future publication.
