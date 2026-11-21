# reports/sta - static timing (PrimeTime) evidence

Raw PrimeTime output. Never edited by hand; regenerate with the scripts named below.

| Directory | Script | What it shows |
|---|---|---|
| `mc_top_shared_5ns_clkslew/` | `scripts/sta/pt_clock_transition_check.tcl` | The gscl45nm `DFFPOSX1` setup-table artefact isolated by a clock-transition sensitivity run on the committed one-lane netlist (`reports/syn/mc_top_shared_5ns`). `summary.txt`: at the SDC's 0.10 ns clock transition the worst path is the B*z multiplier at -0.200 ns because the corrupt table charges 1.42 ns of setup; at 0.06 ns (the table's clean row) the same path shows +1.12 ns and the design's true worst path appears: `rng_lane` `s0 -> (s0+s3) -> rotl -> (+s0) -> u[31]`, 4.76 ns of logic, +0.055 ns. See Gaussian work plan Sec. 6.1 item 3 and PR #11 review. |

The `DFFPOSX1` `setup_rising` table in `gscl45nm.lib` has four corrupt entries (6.2, 5.125,
3.075 ns rise; 5.85 ns fall) at CLK transition 0.3-0.6 ns, 15-60x their neighbours. With a
0.10 ns clock transition DC and PT interpolate toward them and charge 1.2-1.4 ns of setup,
about 10x the realistic value, on every path ending in a `DFFPOSX1`. `DFFSR`'s table is clean.
