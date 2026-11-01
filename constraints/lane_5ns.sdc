# Common timing constraints for every block and configuration in the comparison.
# Target: 200 MHz on gscl45nm (FreePDK45), typical corner, 1.1 V, 27 C.
# Hold these constant across all synthesis runs so PPA numbers are comparable
# (Project plan: "same library, clock, constraints, utilization policy").

if {![info exists CLK_PERIOD]} { set CLK_PERIOD 5.0 }

create_clock -name clk -period $CLK_PERIOD [get_ports clk]
set_clock_uncertainty 0.10 [get_clocks clk]
set_clock_transition  0.10 [get_clocks clk]

# Blocks are pipeline stages: budget 30% of the period at each boundary so a
# block that closes here also closes when wired to its neighbours.
set IO_DELAY [expr {0.3 * $CLK_PERIOD}]
set_input_delay  $IO_DELAY -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay $IO_DELAY -clock clk [all_outputs]

# Reset (spec D-2): asynchronous assert, synchronous de-assert via rst_sync in
# mc_top. Assertion is untimed; de-assertion arrives synchronously, so rst_n is
# constrained like a data input (above) and DC/PT check the DFFSR recovery and
# removal arcs. Do NOT false-path rst_n - that would silence exactly those checks.

# Drive / load: a typical library inverter on inputs, a few gate loads on outputs.
set_driving_cell -lib_cell INVX1 -pin Y [remove_from_collection [all_inputs] [get_ports clk]]
set_load 0.010 [all_outputs]

set_max_transition 0.30 [current_design]
set_max_fanout 16 [current_design]
