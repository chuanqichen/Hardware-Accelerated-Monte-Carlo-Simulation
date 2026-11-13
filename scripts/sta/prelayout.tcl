# Independent PrimeTime check of a mapped netlist and its exported SDC.
# No SPEF, propagated clock, or physical/power signoff is implied.
set root [file normalize [file join [file dirname [info script]] ../..]]
if {[catch {
  foreach name {NETLIST MAPPED_SDC} {
    if {![info exists ::env($name)] || ![file isfile $::env($name)]} {
      error "$name must name an existing mapped input"
    }
  }
  set netlist [file normalize $::env(NETLIST)]
  set sdc [file normalize $::env(MAPPED_SDC)]
  set lib /usr/local/packages/FreePDK45/osu_soc/lib/files/gscl45nm.db
  if {[info exists ::env(LIB_DB)]} { set lib $::env(LIB_DB) }
  if {![file isfile $lib]} { error "Missing standard-cell .db: $lib" }
  set tag "mc_top_[clock format [clock seconds] -format %Y%m%d_%H%M%S]"
  if {[info exists ::env(STA_TAG)]} { set tag $::env(STA_TAG) }
  if {![regexp {^[A-Za-z0-9][A-Za-z0-9_.-]*$} $tag]} { error "Invalid STA_TAG" }
  set out [file join $root reports sta $tag]
  if {[file exists $out]} { error "Run exists: $out; choose a fresh STA_TAG" }
  file mkdir $out
  set f [open $out/source_sha256.txt w]
  puts $f [exec sha256sum $netlist $sdc $lib [info script]]
  close $f
  set f [open $out/inputs.txt w]
  puts $f "tool=[get_app_var sh_product_version]"
  puts $f "netlist=$netlist\nsdc=$sdc\nlibrary=$lib\ncorner=typical"
  puts $f "analysis=prelayout_ideal_clock_no_extracted_parasitics"
  close $f
  set_app_var link_path [list * $lib]
  set_app_var link_create_black_boxes false
  # PrimeTime checks the characterized recovery/removal arcs by default; audit
  # the actual tested/untested counts below instead of creating an unknown var.
  read_verilog $netlist
  if {![link_design mc_top]} { error "PrimeTime link failed" }
  set_operating_conditions typical
  read_sdc $sdc
  update_timing
  check_timing -verbose > $out/check_timing.rpt
  report_units > $out/units.rpt
  report_clock > $out/clock.rpt
  report_timing -delay_type max -max_paths 5 -nosplit -significant_digits 6 > $out/setup.rpt
  report_timing -delay_type min -max_paths 5 -nosplit -significant_digits 6 > $out/hold.rpt
  report_constraint -all_violators -nosplit -significant_digits 6 > $out/violators.rpt
  report_analysis_coverage > $out/coverage.rpt
  report_disable_timing > $out/disabled_timing.rpt
  set pins [get_pins -of_objects [all_registers] -filter "lib_pin_name == R || lib_pin_name == S"]
  redirect $out/reset_timing.rpt {
    if {[sizeof_collection $pins] > 0} {
      report_timing -delay_type max -to $pins -max_paths 2 -nosplit -significant_digits 6
      report_timing -delay_type min -to $pins -max_paths 2 -nosplit -significant_digits 6
    } else { puts "No asynchronous reset pins" }
  }
  set setup [get_timing_paths -delay_type max -max_paths 1]
  set hold [get_timing_paths -delay_type min -max_paths 1]
  if {[sizeof_collection $setup] != 1 || [sizeof_collection $hold] != 1} {
    error "Missing setup or hold timing paths"
  }
  set f [open $out/summary.txt w]
  puts $f "design=mc_top\nsetup_slack_ns=[get_attribute $setup slack]"
  puts $f "hold_slack_ns=[get_attribute $hold slack]"
  puts $f "result=analysis_completed_review_violations_and_coverage"
  close $f
} reason]} {
  puts stderr "STA failed: $reason"
  exit 1
}
puts "STA_DONE $tag (pre-layout; inspect hold, electrical and coverage reports)"
exit 0
