# Design Compiler synthesis of one block / configuration on gscl45nm (FreePDK45).
#
# Driven entirely by environment variables so the same script serves every block
# and every point of the parameter sweep (scripts/syn/run_sweep.sh):
#
#   DESIGN      top module name                       e.g. gauss_lut
#   RTL_FILES   space-separated SystemVerilog files,   e.g. "rtl/mc_pkg.sv rtl/generated/gauss_lut_rom.sv rtl/gauss_lut.sv"
#               in compile order (packages first)
#   PARAMS      comma-separated top-level parameter    e.g. "ADDR_BITS=10,OUT_WIDTH=16,FRAC_BITS=12,LATENCY=1"
#               overrides (optional)
#   TAG         run name used for the report folder    e.g. gauss_lut_a10_w16_l1
#   SDC         constraints file                       default constraints/lane_5ns.sdc
#   REPORT_DIR  where raw reports go                   default reports/syn/$TAG
#   LIB_DB      standard-cell .db                      default FreePDK45 gscl45nm.db on peach
#
# Usage (peach, login shell with `module load syn/2022`):
#   DESIGN=gauss_lut RTL_FILES="..." PARAMS="ADDR_BITS=10,..." TAG=gauss_lut_a10_w16_l1 \
#     dc_shell -f scripts/syn/dc_synth.tcl | tee reports/syn/gauss_lut_a10_w16_l1/dc.log
#
# Outputs in $REPORT_DIR: area.rpt timing.rpt power.rpt qor.rpt resources.rpt
# cells.rpt, the mapped netlist $DESIGN.mapped.v, the post-synthesis SDC, and
# summary.txt (one line per key metric, parsed by scripts/parse_reports.py).

set repo_root [file normalize [file join [file dirname [info script]] ../..]]
source [file join $repo_root scripts syn config.tcl]
if {[catch {mc_synth_config $repo_root} cfg]} {
  puts stderr "Synthesis setup error: $cfg"
  exit 2
}
set DESIGN [dict get $cfg design]
set RTL_FILES [dict get $cfg sources]
set PARAMS [dict get $cfg params]
set TAG [dict get $cfg tag]
set SDC [dict get $cfg sdc]
set REPORT_DIR [dict get $cfg report_dir]
set LIB_DB [dict get $cfg library]
set CLK_PERIOD [dict get $cfg period]
set OPCOND [dict get $cfg corner]

if {[catch {
file mkdir $REPORT_DIR
file mkdir $REPORT_DIR/work
define_design_lib WORK -path $REPORT_DIR/work
set_svf $REPORT_DIR/design.svf
set fd [open $REPORT_DIR/source_sha256.txt w]
puts $fd [exec sha256sum {*}$RTL_FILES $SDC [file join $repo_root scripts syn config.tcl] [file join $repo_root scripts syn dc_synth.tcl]]
close $fd
set fd [open $REPORT_DIR/library_sha256.txt w]
puts $fd [exec sha256sum $LIB_DB]
close $fd
set fd [open $REPORT_DIR/inputs.txt w]
puts $fd "top=$DESIGN"
puts $fd "corner_label=$OPCOND"
puts $fd "clock_period_ns=$CLK_PERIOD"
puts $fd "params=$PARAMS"
puts $fd "sources=$RTL_FILES"
puts $fd "library=$LIB_DB"
puts $fd "tool=[get_app_var sh_product_version]"
if {![catch {exec git -C $repo_root rev-parse HEAD} revision]} { puts $fd "git_revision=$revision" }
close $fd

# ---- library ------------------------------------------------------------------
set_app_var target_library $LIB_DB
set_app_var link_library   "* $LIB_DB"
# gscl45nm has no DesignWare-specific library; DC's generic DW components still map.
set_app_var synthetic_library {dw_foundation.sldb}
set_app_var link_library "$link_library dw_foundation.sldb"

# ---- read and elaborate -------------------------------------------------------
# Packages must be analyzed before the modules that import them.
foreach f $RTL_FILES {
  if {![analyze -format sverilog $f]} { puts "ERROR: analyze failed on $f"; exit 1 }
}
set elab_args [list $DESIGN]
if {$PARAMS ne ""} {
  # "A=1,B=2" -> "A=>1,B=>2" (DC's -parameters syntax)
  set p [string map {"=" "=>"} $PARAMS]
  lappend elab_args -parameters $p
}
if {![eval elaborate $elab_args]} { puts "ERROR: elaborate failed"; exit 1 }
# Elaborating with -parameters renames the design (e.g. gauss_lut_ADDR_BITS10_...);
# rename back so reports and the netlist are predictable.
set elab_name [get_object_name [current_design]]
if {$elab_name ne $DESIGN} { rename_design $elab_name $DESIGN }
current_design $DESIGN
if {![link]} { error "Link failed" }
if {![check_design]} { error "check_design failed" }
check_design > $REPORT_DIR/check_design.rpt
set_operating_conditions $OPCOND
report_units > $REPORT_DIR/units.rpt

# ---- constraints --------------------------------------------------------------
source $SDC

# ---- compile ------------------------------------------------------------------
# No hierarchy to keep for a single block; flatten so the ROM logic can be
# optimised with its consumer. Retiming is left off for now so the latency
# measured in simulation is the latency synthesised (LATENCY / MUL_STAGES are
# the knobs, as documented in the work plans).
set_app_var compile_ultra_ungroup_dw true
# Spec D-2: async reset. DC ignores the DFFSR recovery/removal arcs unless this
# is set, and then reports the reset de-assertion path as "unconstrained".
set_app_var enable_recovery_removal_arcs true
# Hold is left to P&R (ideal clock here); the enable-mux feedback on DFFPOSX1
# shows -0.03 ns and is listed in violators.rpt for the record.
if {![compile_ultra -no_autoungroup]} { error "compile_ultra failed" }
# Second pass to recover area once timing is met.
optimize_netlist -area
if {![check_design]} { error "post-compile check_design failed" }
check_timing > $REPORT_DIR/timing_check.rpt

# ---- reports ------------------------------------------------------------------
report_area      -hierarchy -nosplit        > $REPORT_DIR/area.rpt
report_timing    -max_paths 5 -nosplit -transition_time -capacitance \
                                            > $REPORT_DIR/timing.rpt
report_power     -nosplit -analysis_effort medium \
                                            > $REPORT_DIR/power.rpt
report_qor                                  > $REPORT_DIR/qor.rpt
report_resources -nosplit                   > $REPORT_DIR/resources.rpt
report_reference -nosplit                   > $REPORT_DIR/cells.rpt
report_constraint -all_violators -nosplit   > $REPORT_DIR/violators.rpt
# Full constraint summary (not just violators): includes the recovery/removal
# rows for the async reset pins (spec D-2) and the hold summary.
report_constraint -nosplit -significant_digits 4 > $REPORT_DIR/constraints.rpt
# Reset de-assertion paths explicitly, so the D-2 obligation is auditable.
set async_pins [get_pins -of_objects [all_registers] -filter "lib_pin_name == R || lib_pin_name == S"]
redirect $REPORT_DIR/reset_timing.rpt {
  if {[sizeof_collection $async_pins] > 0} {
    report_timing -delay_type max -to $async_pins -max_paths 2 -nosplit
    report_timing -delay_type min -to $async_pins -max_paths 2 -nosplit
  } else { puts "no asynchronous reset pins in this design" }
}

# ---- outputs for P&R and for the parser ---------------------------------------
change_names -rules verilog -hierarchy
write -format verilog -hierarchy -output $REPORT_DIR/$DESIGN.mapped.v
write_sdc $REPORT_DIR/$DESIGN.mapped.sdc
write -format ddc -hierarchy -output $REPORT_DIR/$DESIGN.mapped.ddc

# One-line-per-metric summary. Numbers come from DC collections, not from
# re-parsing the text reports, so the CSV stays robust to report formatting.
set clk_period [get_attribute [get_clocks clk] period]
set wns        [get_attribute [get_timing_paths -max_paths 1] slack]
# Design-level area is only exposed through report_area in this DC release.
redirect -variable area_rpt {report_area -nosplit}
foreach {key pat} {area_comb "Combinational area:" area_bufinv "Buf/Inv area:" \
                   area_seq "Noncombinational area:" area_total "Total cell area:"} {
  set $key ""
  regexp "$pat\\s+(\[\\d.\]+)" $area_rpt -> $key
}
set cell_count [sizeof_collection [get_cells -hierarchical -filter "is_hierarchical == false"]]
set seq_count  [sizeof_collection [all_registers]]
set f [open $REPORT_DIR/summary.txt w]
puts $f "design       $DESIGN"
puts $f "tag          $TAG"
puts $f "params       $PARAMS"
puts $f "library      [file tail $LIB_DB]"
puts $f "clk_period_ns $clk_period"
puts $f "wns_ns       $wns"
puts $f "fmax_mhz     [expr {1000.0 / ($clk_period - $wns)}]"
puts $f "area_um2     $area_total"
puts $f "area_comb_um2 $area_comb"
puts $f "area_bufinv_um2 $area_bufinv"
puts $f "area_seq_um2 $area_seq"
puts $f "cells        $cell_count"
puts $f "registers    $seq_count"
close $f

} reason]} {
  puts stderr "Synthesis failed: $reason; partial evidence remains in $REPORT_DIR"
  exit 1
}
puts "SYNTH_DONE $TAG area=$area_total wns=$wns (review hold/electrical checks; pre-layout estimate only)"
exit 0
