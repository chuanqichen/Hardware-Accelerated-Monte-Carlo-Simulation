# Compile a specified source without overwriting an existing artifact.
# LIB_SOURCE and LIB_OUTPUT are required; load syn/2022 first.
if {[catch {
    foreach name {LIB_SOURCE LIB_OUTPUT} {
        if {![info exists ::env($name)] || $::env($name) eq ""} { error "Set $name" }
    }
    set source [file normalize $::env(LIB_SOURCE)]
    set output [file normalize $::env(LIB_OUTPUT)]
    if {![file isfile $source] || [file size $source] == 0} { error "Missing Liberty source" }
    if {[file exists $output] || [file exists $output.build.txt]} { error "Output exists: $output" }
    file mkdir [file dirname $output]
    set source_sha [lindex [exec sha256sum $source] 0]
    read_lib $source
    write_lib -format db gscl45nm -output $output
    if {![file isfile $output] || [file size $output] == 0} { error "No compiled library" }
    set f [open $output.build.txt w]
    puts $f "source_sha256=$source_sha"
    puts $f "db_sha256=[lindex [exec sha256sum $output] 0]"
    puts $f "tool=[get_app_var sh_product_version]"
    puts $f "library_name=gscl45nm"
    puts $f "command=read_lib; write_lib -format db gscl45nm"
    close $f
} reason]} {
    puts stderr "LIBRARY failed: $reason"
    exit 1
}
puts "LIBRARY_DONE $output"
exit 0
