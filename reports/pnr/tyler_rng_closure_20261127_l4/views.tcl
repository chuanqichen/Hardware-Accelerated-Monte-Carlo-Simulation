create_library_set -name typical_lib -timing /home/work/teh969/mc_rngphysical_20261127/tech/gscl45nm/setup_fixed_v1/gscl45nm.lib
create_rc_corner -name typical_rc -T 27
create_delay_corner -name typical_delay -library_set typical_lib -rc_corner typical_rc
create_constraint_mode -name functional -sdc_files /home/work/teh969/mc_rngphysical_20261127/reports/syn/tyler_rng_syn24_20261127_l4/mc_top.mapped.sdc
create_analysis_view -name functional -constraint_mode functional -delay_corner typical_delay
set_analysis_view -setup {functional} -hold {functional}
