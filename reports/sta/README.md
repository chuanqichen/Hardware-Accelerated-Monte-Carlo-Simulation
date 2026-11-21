# reports/sta - static timing (PrimeTime) evidence

## Reproduction and interpretation

Use `NETLIST=... SDC=... OUT=reports/sta/<fresh-tag> bash scripts/sta/clock_transition.sh`.
The wrapper rejects exit-zero command errors and incomplete evidence. Both the
wrapper and Tcl refuse to overwrite a previous run. New runs record input/library
SHA-256 hashes, tool version and both transition assumptions. Historical reports
below are preserved unchanged and predate this metadata gate.

The 0.06 ns run changes the assumed clock transition. It is a sensitivity study,
not a repaired library, measured clock slew, or 200 MHz signoff. The setup-table
anomaly described below needs TA/library review. Hold, capacitance, coverage and
routed-clock issues remain open; the positive setup slack does not waive them.

Raw PrimeTime output. Never edited by hand; regenerate with the scripts named below.

| Directory | Script | What it shows |
|---|---|---|
| `mc_top_shared_5ns_clkslew/` | `scripts/sta/pt_clock_transition_check.tcl` | The gscl45nm `DFFPOSX1` setup-table artefact isolated by a clock-transition sensitivity run on the committed one-lane netlist (`reports/syn/mc_top_shared_5ns`). `summary.txt`: at the SDC's 0.10 ns clock transition the worst path is the B*z multiplier at -0.200 ns because the corrupt table charges 1.42 ns of setup; at 0.06 ns (the table's clean row) the same path shows +1.12 ns and the design's true worst path appears: `rng_lane` `s0 -> (s0+s3) -> rotl -> (+s0) -> u[31]`, 4.76 ns of logic, +0.055 ns. See Gaussian work plan Sec. 6.1 item 3 and PR #11 review. |

The `DFFPOSX1` `setup_rising` table in `gscl45nm.lib` has four corrupt entries (6.2, 5.125,
3.075 ns rise; 5.85 ns fall) at CLK transition 0.3-0.6 ns, 15-60x their neighbours. With a
0.10 ns clock transition DC and PT interpolate toward them and charge 1.2-1.4 ns of setup,
about 10x the realistic value, on every path ending in a `DFFPOSX1`. `DFFSR`'s table is clean.
