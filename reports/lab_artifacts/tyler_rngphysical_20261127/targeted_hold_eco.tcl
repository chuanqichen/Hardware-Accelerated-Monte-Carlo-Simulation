# Read-only parent checkpoint; write a fresh routed child with explicit hold buffers.
# This experiment does not alter the shared implementation flow or the SDC.
set root [file normalize [file join [file dirname [info script]] ../../..]]
if {[catch {
  foreach name {PARENT_TAG ECO_TAG ECO_PINS} {
    if {![info exists ::env($name)] || $::env($name) eq ""} { error "Set $name" }
  }
  foreach name {PARENT_TAG ECO_TAG} {
    if {![regexp {^[A-Za-z0-9][A-Za-z0-9_.-]*$} $::env($name)]} { error "Invalid $name" }
  }
  set parent [file join $root reports pnr $::env(PARENT_TAG)]
  set out [file join $root reports pnr $::env(ECO_TAG)]
  set db [file join $parent mc_top.enc.dat]
  if {![file isdirectory $db]} { error "Missing parent database: $db" }
  if {[file exists $out]} { error "Output already exists: $out" }
  set pins $::env(ECO_PINS)
  file mkdir $out
  file copy $parent/inputs.txt $out/inputs.txt
  file copy $parent/source_sha256.txt $out/source_sha256.txt
  file copy $parent/output_sha256.txt $out/parent_output_sha256.txt
  set f [open $out/inputs.txt a]
  puts $f "eco_parent_tag=$::env(PARENT_TAG)"
  puts $f "eco_initial_state=saved_routed_database"
  puts $f "eco_policy=BUFX2_at_explicit_negative_hold_endpoints"
  puts $f "eco_pins=$pins"
  close $f
  set f [open $out/source_sha256.txt a]
  puts $f [exec sha256sum [info script]]
  close $f
  set files [exec find $db -type f]
  set f [open $out/parent_database_sha256.txt w]
  puts $f [exec sha256sum {*}[split $files \n]]
  close $f
  setMultiCpuUsage -localCpu 4
  restoreDesign $db mc_top
  setAnalysisMode -analysisType onChipVariation -cppr none
  setDelayCalMode -SIAware true
  setEcoMode -refinePlace true -updateTiming true
  set i 0
  foreach pin $pins {
    if {[sizeof_collection [get_pins $pin]] != 1} { error "Expected one endpoint: $pin" }
    puts "TARGETED_HOLD_BUFFER $pin"
    puts [ecoAddRepeater -term [list $pin] -cell BUFX2 -relativeDistToSink 0.1 -name tyler_hold_eco_$i]
    incr i
  }
  ecoRoute
  globalNetConnect vdd -type pgpin -pin vdd -all
  globalNetConnect gnd -type pgpin -pin gnd -all
  setExtractRCMode -engine postRoute -effortLevel low
  extractRC
  timeDesign -postRoute -outDir $out/postroute -prefix mc_top
  timeDesign -postRoute -hold -outDir $out/postroute_hold -prefix mc_top
  verifyGeometry -report $out/geometry.rpt
  verifyConnectivity -type all -report $out/connectivity.rpt
  summaryReport -noHtml -outfile $out/implementation.rpt
  report_ccopt_clock_trees -file $out/clock_trees.rpt
  report_ccopt_skew_groups -file $out/clock_skew.rpt
  saveNetlist -excludeLeafCell $out/mc_top.routed.v
  write_sdc $out/mc_top.routed.sdc
  rcOut -spef $out/mc_top.routed.spef
  defOut -floorplan -netlist -routing $out/mc_top.routed.def
  set pdk /usr/local/packages/FreePDK45/osu_soc
  set gds [glob $pdk/lib/source/gds/*.gds]
  streamOut $out/mc_top.gds -mapFile $pdk/lib/files/gds2_encounter.map -merge $gds -units 1000 -mode ALL
  saveDesign $out/mc_top.enc
  set f [open $out/summary.txt w]
  puts $f "design=mc_top\ntag=$::env(ECO_TAG)"
  puts $f "die_box=[dbGet top.fplan.box]\ncore_box=[dbGet top.fplan.coreBox]"
  puts $f "placed_instances_including_fillers=[llength [dbGet top.insts]]"
  puts $f "result=targeted_hold_ECO_completed_review_all_reports"
  close $f
  set files {}
  foreach suffix {routed.v routed.sdc routed.spef routed.def gds} {
    set path $out/mc_top.$suffix
    if {![file isfile $path] || [file size $path] == 0} { error "Missing output: $path" }
    lappend files $path
  }
  set f [open $out/output_sha256.txt w]
  puts $f [exec sha256sum {*}$files]
  close $f
} reason]} {
  puts stderr "TARGETED_HOLD_ECO failed: $reason"
  puts stderr $::errorInfo
  exit 1
}
puts "PNR_DONE $::env(ECO_TAG) (targeted hold ECO; inspect all reports)"
exit 0
