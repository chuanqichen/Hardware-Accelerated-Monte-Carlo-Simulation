# Run from the repository root: dc_shell -f scripts/syn/dc_synth.tcl
# Never reads teammate branches or includes tb/mocks in a production design.
set repo_root [file normalize [file join [file dirname [info script]] ../..]]
source [file join $repo_root scripts syn config.tcl]
if {[catch {mc_synth_config $repo_root} cfg]} {
    puts stderr "Synthesis setup error: $cfg"
    exit 2
}
set run_dir [dict get $cfg run_dir]
file mkdir $run_dir
set top [dict get $cfg top]
set CLOCK_PERIOD_NS [dict get $cfg period]
set target_library [dict get $cfg libraries]
set link_library [concat [list *] $target_library]
set search_path [concat $search_path [list $repo_root]]
define_design_lib WORK -path [file join $run_dir work]
set_svf [file join $run_dir design.svf]

set metadata [open [file join $run_dir inputs.txt] w]
puts $metadata "top=$top"
puts $metadata "corner_label=[dict get $cfg corner]"
puts $metadata "target_libraries=$target_library"
puts $metadata "clock_period_ns=$CLOCK_PERIOD_NS"
puts $metadata "sources=[dict get $cfg sources]"
puts $metadata "tool=[get_app_var sh_product_version]"
if {[info exists ::env(MC_SOURCE_REVISION)]} {
    puts $metadata "source_revision_label=$::env(MC_SOURCE_REVISION)"
}
if {![catch {exec git -C $repo_root rev-parse HEAD} revision]} {
    puts $metadata "git_revision=$revision"
    if {![catch {exec git -C $repo_root status --porcelain} changes]} {
        puts $metadata "working_tree_changes=$changes"
    }
}
close $metadata
set snapshot_files [concat [dict get $cfg sources] [list \
    [file join $repo_root constraints mc.sdc] \
    [file join $repo_root scripts syn config.tcl] \
    [file join $repo_root scripts syn dc_synth.tcl]]]
set manifest [open [file join $run_dir source_sha256.txt] w]
puts $manifest [exec sha256sum {*}$snapshot_files]
close $manifest
set manifest [open [file join $run_dir library_sha256.txt] w]
puts $manifest [exec sha256sum {*}$target_library]
close $manifest

if {[catch {
    analyze -format sverilog [dict get $cfg sources]
    elaborate $top
    current_design $top
    if {![link]} { error "link failed; check library and unresolved modules" }
    if {![check_design]} { error "check_design failed" }
    set_operating_conditions [dict get $cfg corner]
    source [file join $repo_root constraints mc.sdc]
    redirect -file [file join $run_dir library.rpt] {
        foreach_in_collection lib [get_libs *] { report_lib [get_object_name $lib] }
    }
    redirect -file [file join $run_dir units.rpt] { report_units }
    redirect -file [file join $run_dir precompile_check.rpt] { check_timing }
    compile -map_effort medium
    if {![check_design]} { error "post-compile check_design failed" }
    redirect -file [file join $run_dir area.rpt] { report_area -hierarchy }
    redirect -file [file join $run_dir timing.rpt] { report_timing -delay_type max -max_paths 10 }
    redirect -file [file join $run_dir constraints.rpt] { report_constraint -all_violators }
    redirect -file [file join $run_dir timing_check.rpt] { check_timing }
    redirect -file [file join $run_dir qor.rpt] { report_qor }
    write -format ddc -hierarchy -output [file join $run_dir ${top}.ddc]
    write -format verilog -hierarchy -output [file join $run_dir ${top}.v]
    write_sdc [file join $run_dir ${top}.sdc]
} reason]} {
    puts stderr "Synthesis failed: $reason; partial evidence remains in $run_dir"
    exit 1
}
puts "Synthesis run finished: $run_dir. Review units, mapping, constraints and slack before claiming timing closure."
exit 0
