# Read-only Innovus timing diagnostic for a saved routed mc_top database.
#   PNR_DB=<reports/pnr/tag>/mc_top.enc.dat DIAG_DIR=<fresh directory> \
#     innovus -no_gui -files scripts/pnr/timing_diagnostics.tcl
# Reports post-route setup/hold with SI-aware delay calculation on and off, so
# Innovus/PrimeTime differences can be attributed before changing the design.
# Optional DIAG_SETUP_TO and DIAG_HOLD_TO list endpoint pins to report in full,
# for a same-path comparison with the PrimeTime reports.
# The database is restored, re-extracted with the flow's settings and not saved.
if {[catch {
  foreach name {PNR_DB DIAG_DIR} {
    if {![info exists ::env($name)] || $::env($name) eq ""} { error "Set $name" }
  }
  set db [file normalize $::env(PNR_DB)]
  set out [file normalize $::env(DIAG_DIR)]
  if {![file isdirectory $db]} { error "Missing PNR_DB: $db" }
  if {[file exists $out]} { error "Diagnostics exist: $out" }
  file mkdir $out
  setMultiCpuUsage -localCpu 4
  restoreDesign $db mc_top
  setAnalysisMode -analysisType onChipVariation -cppr none
  setExtractRCMode -engine postRoute -effortLevel low
  extractRC
  set setup_pins [expr {[info exists ::env(DIAG_SETUP_TO)] ? $::env(DIAG_SETUP_TO) : ""}]
  set hold_pins [expr {[info exists ::env(DIAG_HOLD_TO)] ? $::env(DIAG_HOLD_TO) : ""}]
  foreach si {true false} {
    setDelayCalMode -SIAware $si
    timeDesign -postRoute -outDir $out/si_$si -prefix mc_top
    timeDesign -postRoute -hold -outDir $out/si_${si}_hold -prefix mc_top
    foreach pin $setup_pins {
      report_timing -late -to $pin -path_type full_clock -net >> $out/si_${si}_setup_paths.rpt
    }
    foreach pin $hold_pins {
      report_timing -early -to $pin -path_type full_clock -net >> $out/si_${si}_hold_paths.rpt
    }
  }
  set f [open $out/inputs.txt w]
  puts $f "pnr_db=$db\nextraction=postRoute_effort_low\nanalysis=onChipVariation_cppr_none"
  puts $f "variants=SIAware_true,SIAware_false\ndesign_saved=false"
  close $f
} reason]} {
  puts stderr "Diagnostics failed: $reason"
  exit 1
}
puts "TIMING_DIAGNOSTICS_DONE $out"
exit 0
