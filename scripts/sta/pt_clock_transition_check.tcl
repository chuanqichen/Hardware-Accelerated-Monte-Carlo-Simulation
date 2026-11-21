# Clock-transition sensitivity study, not timing closure or a library repair.
# Run through clock_transition.sh to reject exit-zero PrimeTime command errors.
proc env_or {n d} { if {[info exists ::env($n)] && $::env($n) ne ""} { return $::env($n) }; return $d }
if {[catch {
set NETLIST [env_or NETLIST reports/syn/mc_top_shared_5ns/mc_top.mapped.v]
set SDC     [env_or SDC     reports/syn/mc_top_shared_5ns/mc_top.mapped.sdc]
set TOP     [env_or TOP     mc_top]
set OUT     [env_or OUT     reports/sta/clkslew_[clock format [clock seconds] -format %Y%m%d_%H%M%S]]
set LIB     [env_or LIB_DB  /usr/local/packages/FreePDK45/osu_soc/lib/files/gscl45nm.db]
foreach input [list $NETLIST $SDC $LIB] {
  if {![file isfile $input]} { error "Missing input: $input" }
}
if {[file exists $OUT]} { error "Run exists: $OUT; choose a fresh OUT" }
file mkdir $OUT
set f [open $OUT/source_sha256.txt w]
puts $f [exec sha256sum $NETLIST $SDC $LIB [info script]]
close $f
set f [open $OUT/inputs.txt w]
puts $f "tool=[get_app_var sh_product_version]\ntop=$TOP\nnetlist=$NETLIST\nsdc=$SDC\nlibrary=$LIB"
puts $f "analysis=prelayout_ideal_clock_slew_sensitivity_no_extracted_parasitics"
close $f

set_app_var search_path [list . [file dirname $LIB]]
set_app_var link_path   [list * $LIB]
set_app_var link_create_black_boxes false
# (PrimeTime checks recovery/removal by default; the DC variable does not exist here.)
read_verilog $NETLIST
current_design $TOP
if {![link_design $TOP]} { error "PrimeTime link failed" }
read_sdc $SDC

foreach slew {0.10 0.06} {
  set_clock_transition $slew [get_clocks clk]
  if {[sizeof_collection [get_clocks clk]] != 1} { error "Expected one clock named clk" }
  update_timing
  set p [get_timing_paths -delay_type max -max_paths 1]
  if {[sizeof_collection $p] != 1} { error "Missing setup timing path" }
  set ep   [get_object_name [get_attribute $p endpoint]]
  set arr  [get_attribute $p arrival]
  set slk  [get_attribute $p slack]
  redirect $OUT/setup_clkslew_${slew}.rpt {
    report_timing -delay_type max -max_paths 3 -slack_lesser_than 100 -nosplit -transition_time -significant_digits 4
  }
  # Also the specific path PT flagged in the interim STA, for a like-for-like line.
  redirect -append $OUT/setup_clkslew_${slew}.rpt {
    report_timing -delay_type max -to [get_pins -hierarchical *acc_r_reg*32*/D] -max_paths 1 -nosplit -significant_digits 4
  }
  set line "CLKSLEW $slew worst_endpoint $ep arrival [format %.4f $arr] slack [format %.4f $slk]"
  puts $line
  set f [open $OUT/summary.txt a]; puts $f $line; close $f
}
} reason]} {
  puts stderr "CLKSLEW failed: $reason"
  exit 1
}
puts "CLKSLEW_DONE $OUT (sensitivity only; not timing signoff)"
exit 0
