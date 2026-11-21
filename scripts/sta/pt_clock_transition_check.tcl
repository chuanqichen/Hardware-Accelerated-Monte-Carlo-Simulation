# PrimeTime sensitivity check for the gscl45nm DFFPOSX1 setup-table artefact.
#
# Re-times a mapped netlist with its own SDC, then re-times it once more with the
# clock transition set to 0.06 ns - the first (clean) row of DFFPOSX1's setup
# table in gscl45nm.lib. Everything else is identical. If the worst setup slack
# moves by ~1 ns while arrival times do not change, the reported violation is
# the corrupt table entries (6.2 / 5.125 / 3.075 ns at CLK transition 0.3-0.6),
# not the design. See PR #5 and Gaussian work plan Sec. 6.1 item 3.
#
#   NETLIST=reports/syn/<tag>/mc_top.mapped.v SDC=reports/syn/<tag>/mc_top.mapped.sdc \
#   TOP=mc_top OUT=reports/sta/<tag>_clkslew pt_shell -f scripts/sta/pt_clock_transition_check.tcl
proc env_or {n d} { if {[info exists ::env($n)] && $::env($n) ne ""} { return $::env($n) }; return $d }
set NETLIST [env_or NETLIST reports/syn/mc_top_shared_5ns/mc_top.mapped.v]
set SDC     [env_or SDC     reports/syn/mc_top_shared_5ns/mc_top.mapped.sdc]
set TOP     [env_or TOP     mc_top]
set OUT     [env_or OUT     reports/sta/mc_top_shared_5ns_clkslew]
set LIB     [env_or LIB_DB  /usr/local/packages/FreePDK45/osu_soc/lib/files/gscl45nm.db]
file mkdir $OUT
file delete -force $OUT/summary.txt

set_app_var search_path [list . [file dirname $LIB]]
set_app_var link_path   [list * [file tail $LIB]]
# (PrimeTime checks recovery/removal by default; the DC variable does not exist here.)
read_verilog $NETLIST
current_design $TOP
link_design
read_sdc $SDC

foreach slew {0.10 0.06} {
  set_clock_transition $slew [get_clocks clk]
  update_timing
  set p [get_timing_paths -delay_type max -max_paths 1]
  set ep   [get_object_name [get_attribute $p endpoint]]
  set arr  [get_attribute $p arrival]
  set slk  [get_attribute $p slack]
  redirect $OUT/setup_clkslew_${slew}.rpt {
    report_timing -delay_type max -max_paths 3 -slack_lesser_than 100 -nosplit -transition_time -significant_digits 4
  }
  # Also the specific path PT flagged in the interim STA, for a like-for-like line.
  redirect -append $OUT/setup_clkslew_${slew}.rpt {
    report_timing -delay_type max -to [get_pins -hierarchical *acc_r_reg*32*/D] -max_paths 1 -nosplit -significant_digits 4
  }
  set line "CLKSLEW $slew worst_endpoint $ep arrival [format %.4f $arr] slack [format %.4f $slk]"
  puts $line
  set f [open $OUT/summary.txt a]; puts $f $line; close $f
}
exit
