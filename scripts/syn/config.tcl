# Validated inputs for the shared PR #5 flow. Pure Tcl; no license required.
proc mc_env_or {name default} {
    if {[info exists ::env($name)] && [string trim $::env($name)] ne ""} { return $::env($name) }
    return $default
}
proc mc_synth_config {repo_root} {
    set design [mc_env_or DESIGN gauss_lut]
    if {![regexp {^[A-Za-z_][A-Za-z0-9_]*$} $design]} { error "Invalid DESIGN" }
    set lib [mc_env_or LIB_DB /usr/local/packages/FreePDK45/osu_soc/lib/files/gscl45nm.db]
    if {![file isfile $lib] || [file extension $lib] ne ".db"} { error "Missing standard-cell .db file: $lib" }
    set sources [mc_env_or RTL_FILES ""]
    if {$sources eq ""} {
        switch -- $design {
            gauss_lut { set sources {rtl/mc_pkg.sv rtl/generated/gauss_lut_rom.sv rtl/gauss_lut.sv} }
            mc_controller { set sources {rtl/mc_controller.sv} }
            mc_top {
                set fd [open [file join $repo_root rtl mc_top.f] r]
                set sources [split [string trim [read $fd]] \n]
                close $fd
            }
            default { error "RTL_FILES is required for DESIGN=$design" }
        }
    }
    set absolute_sources {}
    foreach source $sources {
        set path [file normalize [file join $repo_root $source]]
        if {![file isfile $path]} { error "Missing RTL source: $path" }
        if {[string match */tb/* [string map {\\ /} $path]]} { error "Testbench/mock source is forbidden in synthesis: $path" }
        lappend absolute_sources $path
    }
    set period [mc_env_or CLK_PERIOD_NS 5.0]
    if {![string is double -strict $period] ||
        [catch {expr {double($period) > 0.0 && double($period) < Inf}} valid] || !$valid} {
        error "CLK_PERIOD_NS must be a finite positive number"
    }
    set tag [mc_env_or TAG "${design}_[clock format [clock seconds] -format %Y%m%d_%H%M%S]"]
    if {![regexp {^[A-Za-z0-9][A-Za-z0-9_.-]*$} $tag]} { error "Invalid TAG" }
    set report_dir [file normalize [file join $repo_root [mc_env_or REPORT_DIR reports/syn/$tag]]]
    if {[file exists $report_dir]} { error "Run directory already exists: $report_dir; choose a new TAG" }
    set sdc [file normalize [file join $repo_root [mc_env_or SDC constraints/lane_5ns.sdc]]]
    if {![file isfile $sdc]} { error "Missing SDC: $sdc" }
    set params [mc_env_or PARAMS ""]
    if {$params ne ""} {
        foreach param [split $params ,] {
            if {![regexp {^([A-Za-z_][A-Za-z0-9_]*)=([0-9]+)$} $param -> name value]} {
                error "PARAMS must be comma-separated NAME=integer assignments"
            }
            if {$design eq "mc_top" && $name eq "LANES" && $value != 1} { error "mc_top currently supports LANES=1 only" }
        }
    }
    return [dict create design $design library $lib sources $absolute_sources period $period \
        tag $tag report_dir $report_dir sdc $sdc params $params corner [mc_env_or OPCOND typical]]
}
