# Validated inputs for the shared PR #5 flow. Pure Tcl; no license required.
proc mc_env_or {name default} {
    if {[info exists ::env($name)] && [string trim $::env($name)] ne ""} { return $::env($name) }
    return $default
}
proc mc_library {repo_root format} {
    switch -- $format {
        db { set variable LIB_DB }
        lib { set variable LIB_LIB }
        default { error "Unsupported library format: $format" }
    }
    set db_override [mc_env_or LIB_DB ""]
    set lib_override [mc_env_or LIB_LIB ""]
    if {($db_override eq "") != ($lib_override eq "")} {
        error "Set both LIB_DB and LIB_LIB, or unset both to select the project library"
    }
    if {$db_override ne ""} {
        foreach {kind path} [list db $db_override lib $lib_override] {
            if {![file isfile $path] || [file size $path] == 0 ||
                [file extension $path] ne ".$kind"} {
                error "Missing standard-cell .$kind file: $path"
            }
        }
        return [mc_env_or $variable ""]
    }
    set directory [file normalize [file join $repo_root tech gscl45nm setup_fixed_v1]]
    set f [open [file join $directory SHA256SUMS] r]
    set sums [read $f]
    close $f
    set expected [dict create]
    foreach line [split [string trim $sums] \n] {
        if {![regexp {^([0-9a-f]{64}) +([a-zA-Z0-9_.]+)$} $line -> digest name]} {
            error "Malformed project library checksums"
        }
        dict set expected $name $digest
    }
    if {[dict size $expected] != 2} { error "Expected the project Liberty/DB pair" }
    set command [auto_execok sha256sum]
    if {$command eq ""} {
        set command [auto_execok shasum]
        if {$command eq ""} { error "Need sha256sum or shasum to verify the project library" }
        lappend command -a 256
    }
    foreach name {gscl45nm.lib gscl45nm.db} {
        set path [file join $directory $name]
        if {![file isfile $path] || [file size $path] == 0 ||
            [lindex [exec {*}$command $path] 0] ne [dict get $expected $name]} {
            error "Project library checksum mismatch: $path; run make library-check"
        }
    }
    return [file join $directory gscl45nm.$format]
}
proc mc_synth_config {repo_root} {
    set design [mc_env_or DESIGN gauss_lut]
    if {![regexp {^[A-Za-z_][A-Za-z0-9_]*$} $design]} { error "Invalid DESIGN" }
    set lib [mc_library $repo_root db]
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
    set retime [mc_env_or RETIME 0]
    if {$retime ne "0" && $retime ne "1"} { error "RETIME must be unset, 0 or 1" }
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
            if {$design eq "mc_top" && $name eq "LANES" && $value ni {1 2 4}} {
                error "mc_top supports LANES=1, 2 or 4"
            }
        }
    }
    return [dict create design $design library $lib sources $absolute_sources period $period \
        tag $tag report_dir $report_dir sdc $sdc params $params retime $retime corner [mc_env_or OPCOND typical]]
}
