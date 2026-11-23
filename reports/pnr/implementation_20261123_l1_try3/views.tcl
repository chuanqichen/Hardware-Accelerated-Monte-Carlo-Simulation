create_library_set -name typical_lib -timing /usr/local/packages/FreePDK45/osu_soc/lib/files/gscl45nm.lib
create_rc_corner -name typical_rc -T 27
create_delay_corner -name typical_delay -library_set typical_lib -rc_corner typical_rc
create_constraint_mode -name functional -sdc_files /home/work/cc83382/course-implementation-20261123/reports/syn/implementation_20261123_l1/mc_top.mapped.sdc
create_analysis_view -name functional -constraint_mode functional -delay_corner typical_delay
set_analysis_view -setup {functional} -hold {functional}
