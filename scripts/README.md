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
