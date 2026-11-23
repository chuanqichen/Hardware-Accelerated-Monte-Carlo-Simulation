# Independent PrimeTime check of a netlist and its exported SDC.
# Optional SPEF enables extracted parasitics and propagated clocks.
set root [file normalize [file join [file dirname [info script]] ../..]]
if {[catch {
  foreach name {NETLIST MAPPED_SDC} {
    if {![info exists ::env($name)] || ![file isfile $::env($name)]} {
      error "$name must name an existing mapped input"
    }
  }
  set netlist [file normalize $::env(NETLIST)]
  set sdc [file normalize $::env(MAPPED_SDC)]
  set spef ""
  if {[info exists ::env(SPEF)]} {
    if {![file isfile $::env(SPEF)] || [file size $::env(SPEF)] == 0} {
      error "SPEF must name an existing nonempty parasitic file"
    }
    set spef [file normalize $::env(SPEF)]
  }
  set analysis prelayout_ideal_clock_no_extracted_parasitics
  if {$spef ne ""} { set analysis routed_parasitics_propagated_clocks_review_rc_assumptions }
  set vcd ""
  if {[info exists ::env(VCD)]} {
    foreach name {VCD POWER_WINDOW} {
      if {![info exists ::env($name)] || ![file isfile $::env($name)] || [file size $::env($name)] == 0} {
        error "$name must name an existing nonempty activity input"
      }
    }
    set vcd [file normalize $::env(VCD)]
    set window_file [file normalize $::env(POWER_WINDOW)]
    set f [open $window_file r]
    set window [dict create]
    foreach line [split [string trim [read $f]] \n] {
      if {![regexp {^([a-z_]+)=(\S+)$} $line -> key value]} { error "Malformed activity metadata" }
      dict set window $key $value
    }
    close $f
    set start_ns [dict get $window start_ns]
    set stop_ns [dict get $window stop_ns]
    set trials [dict get $window trials]
    if {![string is double -strict $start_ns] || ![string is double -strict $stop_ns] ||
        ![string is integer -strict $trials] || $trials <= 0 ||
        !($start_ns >= 0 && $stop_ns > $start_ns && $stop_ns < Inf)} {
      error "Invalid activity interval or trial count"
    }
    set power_enable_analysis true
    set power_analysis_mode averaged
  }
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
  if {$spef ne ""} { puts $f [exec sha256sum $spef] }
  if {$vcd ne ""} { puts $f [exec sha256sum $vcd $window_file] }
  close $f
  set f [open $out/inputs.txt w]
  puts $f "tool=[get_app_var sh_product_version]"
  puts $f "netlist=$netlist\nsdc=$sdc\nlibrary=$lib\ncorner=typical"
  puts $f "analysis=$analysis\nspef=$spef"
  if {$vcd ne ""} { puts $f "vcd=$vcd\nactivity_window=$window\nactivity=zero_delay_gate_simulation" }
  close $f
  set_app_var link_path [list * $lib]
  set_app_var link_create_black_boxes false
  # PrimeTime checks the characterized recovery/removal arcs by default; audit
  # the actual tested/untested counts below instead of creating an unknown var.
  read_verilog $netlist
  if {![link_design mc_top]} { error "PrimeTime link failed" }
  set_operating_conditions typical
  # Innovus emits a DC-style design-selection header. PrimeTime selects the
  # design through link_design and rejects an argument to current_design.
  # Its current_design collection also replaces Cadence's get_designs lookup.
  # Preserve every timing constraint and retain both raw and consumed SDCs.
  set f [open $sdc r]
  set sdc_text [read $f]
  close $f
  set f [open $out/constraints.pt.sdc w]
  foreach line [split $sdc_text \n] {
    if {[regexp {^\s*current_design\s+(\S+)\s*$} $line -> selected_design]} {
      if {$selected_design ne "mc_top"} { error "SDC selects unexpected design: $selected_design" }
      puts $f "# mc_top already selected by link_design"
    } else {
      puts $f [string map [list {[get_designs {mc_top}]} {[current_design]}] $line]
    }
  }
  close $f
  set f [open $out/source_sha256.txt a]
  puts $f [exec sha256sum $out/constraints.pt.sdc]
  close $f
  if {[read_sdc $out/constraints.pt.sdc] != 1} { error "Failed to read complete SDC" }
  if {$vcd ne "" && abs([get_attribute [get_clocks clk] period] - [dict get $window clock_period_ns]) > 1e-6} {
    error "Activity clock period differs from the timing constraint"
  }
  if {$spef ne ""} {
    set parasitics_log_file $out/parasitics.log
    read_parasitics $spef
    set_propagated_clock [all_clocks]
    report_annotated_parasitics -check -list_not_annotated -max_nets 100000 > $out/parasitic_annotation.rpt
  }
  update_timing
  check_timing -verbose > $out/check_timing.rpt
  report_units > $out/units.rpt
  report_clock > $out/clock.rpt
  report_timing -delay_type max -max_paths 5 -nosplit -significant_digits 6 -path_type full_clock_expanded > $out/setup.rpt
  report_timing -delay_type min -max_paths 5 -nosplit -significant_digits 6 -path_type full_clock_expanded > $out/hold.rpt
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
  if {$vcd ne ""} {
    read_vcd -strip_path tb_mc_array/dut -zero_delay -time [list $start_ns $stop_ns] $vcd
    update_power
    report_power -verbose > $out/power.rpt
    report_switching_activity > $out/activity.rpt
  }
} reason]} {
  puts stderr "STA failed: $reason"
  exit 1
}
puts "STA_DONE $tag ($analysis; inspect hold, electrical and coverage reports)"
exit 0
