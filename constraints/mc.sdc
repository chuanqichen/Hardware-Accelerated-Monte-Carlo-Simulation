# Shared initial synthesis constraints. Time: ns; capacitance: pF.
# Verify report_units against the selected library before treating reports as PPA.
# 10 ns is a smoke target, not an achieved-frequency claim.
if {![info exists CLOCK_PERIOD_NS]} { set CLOCK_PERIOD_NS 10.0 }
if {![string is double -strict $CLOCK_PERIOD_NS] ||
    [catch {expr {double($CLOCK_PERIOD_NS) > 0.0 && double($CLOCK_PERIOD_NS) < Inf}} valid_period] || !$valid_period} {
    error "CLOCK_PERIOD_NS must be positive"
}
set clock_port [get_ports clk]
if {[sizeof_collection $clock_port] != 1} { error "Expected exactly one clk port" }
create_clock -name core_clk -period $CLOCK_PERIOD_NS $clock_port
set_clock_uncertainty [expr {$CLOCK_PERIOD_NS * 0.02}] [get_clocks core_clk]
set_clock_transition 0.10 [get_clocks core_clk]

set data_inputs [remove_from_collection [all_inputs] $clock_port]
if {[sizeof_collection $data_inputs] > 0} {
    set_input_delay -clock core_clk -max [expr {$CLOCK_PERIOD_NS * 0.10}] $data_inputs
    set_input_delay -clock core_clk -min 0.0 $data_inputs
    set_input_transition 0.10 $data_inputs
}
set outputs [all_outputs]
if {[sizeof_collection $outputs] > 0} {
    set_output_delay -clock core_clk -max [expr {$CLOCK_PERIOD_NS * 0.10}] $outputs
    set_output_delay -clock core_clk -min 0.0 $outputs
    set_load 0.01 $outputs
}
# Deliberately no blanket false/multicycle paths. Reset recovery/removal and
# unconstrained paths must be reviewed, not hidden by a reset false path.
