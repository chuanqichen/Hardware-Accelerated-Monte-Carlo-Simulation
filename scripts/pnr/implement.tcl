# Innovus implementation of a mapped mc_top using the installed OSU/FreePDK45.
# One typical corner, 60% initial utilization, shared exported synthesis SDC.
# Native RC estimates are used unless a matching QRC technology file is supplied.
set root [file normalize [file join [file dirname [info script]] ../..]]
source [file join $root scripts syn config.tcl]
if {[catch {
  set tag [mc_env_or PNR_TAG "mc_top_[clock format [clock seconds] -format %Y%m%d_%H%M%S]"]
  if {![regexp {^[A-Za-z0-9][A-Za-z0-9_.-]*$} $tag]} { error "Invalid PNR_TAG" }
  set out [file join $root reports pnr $tag]
  if {[file exists $out]} { error "Run exists: $out" }
  set pdk /usr/local/packages/FreePDK45/osu_soc
  set netlist [mc_env_or NETLIST ""]
  set sdc [mc_env_or MAPPED_SDC ""]
  set lib [mc_library $root lib]
  set lef [mc_env_or TECH_LEF $pdk/lib/files/gscl45nm.lef]
  set map [mc_env_or GDS_MAP $pdk/lib/files/gds2_encounter.map]
  set gds_dir [mc_env_or CELL_GDS_DIR $pdk/lib/source/gds]
  set qrc [mc_env_or QRC_TECH ""]
  # Optional closure policy. The SDC is unchanged; these settings only tell
  # Innovus to repair the SDC max-fanout limit and to fix hold with extra margin
  # for the independent PrimeTime check. Defaults reproduce the baseline flow.
  set hold_target [mc_env_or HOLD_TARGET_SLACK_NS ""]
  if {$hold_target ne "" && (![string is double -strict $hold_target] ||
      $hold_target < 0 || $hold_target > 0.5)} {
    error "HOLD_TARGET_SLACK_NS must be a number of ns from 0 to 0.5"
  }
  set fix_fanout [mc_env_or FIX_FANOUT_LOAD 0]
  if {$fix_fanout ni {0 1}} { error "FIX_FANOUT_LOAD must be 0 or 1" }
  # gscl45nm defines no fanout_load, so Innovus sees zero fanout load on every
  # net while DC/PT count one per sink. place_opt_design deletes DC's buffer
  # trees first; PRESERVE_SYNTH_BUFFERS keeps them by placing without
  # pre-place buffer removal and then running pre-CTS optimization.
  set preserve_buffers [mc_env_or PRESERVE_SYNTH_BUFFERS 0]
  if {$preserve_buffers ni {0 1}} { error "PRESERVE_SYNTH_BUFFERS must be 0 or 1" }
  set inputs [list $netlist $sdc $lib $lef $map]
  if {$qrc ne ""} { lappend inputs $qrc }
  foreach path $inputs {
    if {![file isfile $path] || [file size $path] == 0} { error "Missing/empty input: $path" }
  }
  set gds [glob -nocomplain $gds_dir/*.gds]
  if {[llength $gds] == 0} { error "Missing standard-cell GDS files: $gds_dir" }
  set absolute_inputs {}
  foreach path $inputs { lappend absolute_inputs [file normalize $path] }
  set inputs $absolute_inputs
  set netlist [file normalize $netlist]
  set sdc [file normalize $sdc]
  file mkdir $out
  set f [open $out/source_sha256.txt w]
  puts $f [exec sha256sum {*}$inputs {*}$gds [info script] [file join $root scripts syn config.tcl]]
  close $f
  set f [open $out/inputs.txt w]
  puts $f "netlist=$netlist\nsdc=$sdc\nlibrary=$lib\nlef=$lef"
  puts $f "corner=typical\ninitial_utilization=0.60\ncore_margin_um=20"
  puts $f "cts_target_transition_ns=0.10\ncts_target_skew_ns=0.10\nupdate_io_latency=false"
  puts $f "timing_mode=nominal_early_late_same_typical_library_no_derates"
  puts $f "qrc_technology=$qrc"
  puts $f "rc_method=[expr {$qrc eq "" ? "native_estimate_no_characterized_cap_table" : "qrc_technology_file"}]"
  puts $f "hold_target_slack_ns=[expr {$hold_target eq "" ? "tool_default" : $hold_target}]"
  puts $f "fix_fanout_load=$fix_fanout"
  puts $f "placement=[expr {$preserve_buffers ? "place_design_noPrePlaceOpt_optDesign_preCTS" : "place_opt_design"}]"
  close $f
  set mmmc [open $out/views.tcl w]
  puts $mmmc [list create_library_set -name typical_lib -timing [list $lib]]
  set rc [list create_rc_corner -name typical_rc -T 27]
  if {$qrc ne ""} { lappend rc -qx_tech_file $qrc }
  puts $mmmc $rc
  puts $mmmc {create_delay_corner -name typical_delay -library_set typical_lib -rc_corner typical_rc}
  puts $mmmc [list create_constraint_mode -name functional -sdc_files [list $sdc]]
  puts $mmmc {create_analysis_view -name functional -constraint_mode functional -delay_corner typical_delay}
  puts $mmmc {set_analysis_view -setup {functional} -hold {functional}}
  close $mmmc

  set init_top_cell mc_top
  set init_verilog $netlist
  set init_lef_file [list $lef]
  set init_mmmc_file $out/views.tcl
  set init_pwr_net vdd
  set init_gnd_net gnd
  setMultiCpuUsage -localCpu 4
  setDesignMode -process 45
  init_design
  set_interactive_constraint_modes {functional}
  # Post-route SI optimization requires the early/late analysis engine.
  # Both sides use the same typical library; no PVT/OCV coverage is claimed.
  setAnalysisMode -analysisType onChipVariation -cppr none
  if {$fix_fanout} { setOptMode -fixFanoutLoad true }
  if {$hold_target ne ""} { setOptMode -holdTargetSlack $hold_target }
  floorPlan -site CoreSite -r 1.0 0.60 20 20 20 20
  globalNetConnect vdd -type pgpin -pin vdd -all
  globalNetConnect gnd -type pgpin -pin gnd -all
  globalNetConnect vdd -type tiehi -all
  globalNetConnect gnd -type tielo -all
  set in_pins [dbGet [dbGet -p top.terms.direction input].name]
  set out_pins [dbGet [dbGet -p top.terms.direction output].name]
  editPin -pin $in_pins -side LEFT -layer metal3 -spreadType SIDE
  editPin -pin $out_pins -side RIGHT -layer metal3 -spreadType SIDE
  addRing -nets {gnd vdd} -type core_rings -follow core -center 1 \
    -layer {top metal5 bottom metal5 left metal6 right metal6} \
    -width 5 -spacing 5
  addStripe -nets {gnd vdd} -layer metal6 -direction vertical \
    -width 2 -spacing 2 -set_to_set_distance 40
  sroute -connect {corePin floatingStripe} -nets {gnd vdd}
  if {$preserve_buffers} {
    place_design -noPrePlaceOpt
    optDesign -preCTS
  } else {
    place_opt_design
  }
  saveDesign $out/placed.enc
  timeDesign -preCTS -outDir $out/prects -prefix mc_top

  set_ccopt_property buffer_cells {BUFX2 BUFX4}
  set_ccopt_property inverter_cells {INVX1 INVX2}
  # Match the common initial clock transition with physical buffers; keep the
  # original I/O reference latency instead of automatically rebudgeting it.
  set_ccopt_property target_max_trans 0.10
  set_ccopt_property target_skew 0.10
  set_ccopt_property update_io_latency false
  create_ccopt_clock_tree_spec -file $out/clock_tree.tcl
  ccopt_design -cts
  set_propagated_clock [all_clocks]
  optDesign -postCTS -setup
  optDesign -postCTS -hold
  report_ccopt_clock_trees -file $out/clock_trees.rpt
  report_ccopt_skew_groups -file $out/clock_skew.rpt
  setNanoRouteMode -routeBottomRoutingLayer 1 -routeTopRoutingLayer 10
  routeDesign
  optDesign -postRoute -setup
  optDesign -postRoute -hold
  addFiller -cell FILL -prefix FILL
  globalNetConnect vdd -type pgpin -pin vdd -all
  globalNetConnect gnd -type pgpin -pin gnd -all
  setExtractRCMode -engine postRoute -effortLevel low
  extractRC
  timeDesign -postRoute -outDir $out/postroute -prefix mc_top
  timeDesign -postRoute -hold -outDir $out/postroute_hold -prefix mc_top
  verifyGeometry -report $out/geometry.rpt
  verifyConnectivity -type all -report $out/connectivity.rpt
  summaryReport -noHtml -outfile $out/implementation.rpt
  saveNetlist -excludeLeafCell $out/mc_top.routed.v
  write_sdc $out/mc_top.routed.sdc
  rcOut -spef $out/mc_top.routed.spef
  defOut -floorplan -netlist -routing $out/mc_top.routed.def
  streamOut $out/mc_top.gds -mapFile $map -merge $gds -units 1000 -mode ALL
  saveDesign $out/mc_top.enc
  set f [open $out/summary.txt w]
  puts $f "design=mc_top\ntag=$tag"
  puts $f "die_box=[dbGet top.fplan.box]\ncore_box=[dbGet top.fplan.coreBox]"
  puts $f "placed_instances_including_fillers=[llength [dbGet top.insts]]"
  puts $f "result=implementation_completed_review_timing_drc_connectivity_and_rc_assumptions"
  close $f
  foreach filename {mc_top.routed.v mc_top.routed.sdc mc_top.routed.spef mc_top.routed.def mc_top.gds geometry.rpt connectivity.rpt} {
    if {![file isfile $out/$filename] || [file size $out/$filename] == 0} {
      error "Missing implementation output: $filename"
    }
  }
} reason]} {
  puts stderr "PNR failed: $reason"
  puts stderr $::errorInfo
  exit 1
}
puts "PNR_DONE $tag (inspect violations and RC assumptions; no signoff claim)"
exit 0
