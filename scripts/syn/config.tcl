# Plain Tcl configuration validation; also executable without a DC license.
proc mc_synth_config {repo_root} {
    foreach key {MC_TARGET_LIBS MC_CORNER} {
        if {![info exists ::env($key)] || [string trim $::env($key)] eq ""} {
            error "$key is required; see scripts/README.md"
        }
    }
    set libs $::env(MC_TARGET_LIBS)
    if {[llength $libs] == 0} { error "MC_TARGET_LIBS must be a Tcl list of .db paths" }
    foreach lib $libs {
        if {[file extension $lib] ne ".db" || ![file isfile $lib]} {
            error "Missing standard-cell .db file: $lib"
        }
    }
    set top gauss_lut
    if {[info exists ::env(MC_TOP)]} { set top $::env(MC_TOP) }
    switch -- $top {
        gauss_lut { set relative_sources {rtl/generated/gauss_lut_rom.sv rtl/gauss_lut.sv} }
        mc_controller { set relative_sources {rtl/mc_controller.sv} }
        mc_top {
            set relative_sources {rtl/mc_pkg.sv rtl/pipe.sv rtl/rng_lane.sv
                rtl/generated/gauss_lut_rom.sv rtl/gauss_lut.sv rtl/generated/exp2_rom.sv
                rtl/exp2_unit.sv rtl/price_dp.sv rtl/accumulator.sv rtl/mc_controller.sv
                rtl/mc_lane_array.sv rtl/mc_top.sv}
        }
        default { error "MC_TOP must be gauss_lut, mc_controller, or mc_top" }
    }
    set sources {}
    foreach relative $relative_sources {
        set path [file join $repo_root $relative]
        if {![file isfile $path]} { error "Missing RTL source: $path" }
        lappend sources $path
    }
    set period 10.0
    if {[info exists ::env(MC_CLOCK_NS)]} { set period $::env(MC_CLOCK_NS) }
    if {![string is double -strict $period] ||
        [catch {expr {double($period) > 0.0 && double($period) < Inf}} valid_period] || !$valid_period} {
        error "MC_CLOCK_NS must be a finite positive number in ns"
    }
    set run_id "${top}_[clock format [clock seconds] -format %Y%m%d_%H%M%S]"
    if {[info exists ::env(MC_RUN_ID)]} { set run_id $::env(MC_RUN_ID) }
    if {![regexp {^[A-Za-z0-9][A-Za-z0-9_.-]*$} $run_id]} {
        error "MC_RUN_ID must contain only letters, digits, underscore, dot, or hyphen"
    }
    set run_dir [file join $repo_root reports syn $run_id]
    if {[file exists $run_dir]} { error "Run directory already exists: $run_dir; choose a new MC_RUN_ID" }
    return [dict create top $top libraries $libs corner $::env(MC_CORNER) \
        sources $sources period $period run_dir $run_dir]
}
