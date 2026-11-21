###################################################################

# Created by write_sdc on Sat Nov 21 15:28:19 2026

###################################################################
set sdc_version 2.1

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current uA
set_operating_conditions typical -library gscl45nm
set_max_transition 0.3 [current_design]
set_max_fanout 16 [current_design]
set_driving_cell -lib_cell INVX1 -pin Y [get_ports LD_seed]
set_load -pin_load 0.01 [get_ports {result[15]}]
set_load -pin_load 0.01 [get_ports {result[14]}]
set_load -pin_load 0.01 [get_ports {result[13]}]
set_load -pin_load 0.01 [get_ports {result[12]}]
set_load -pin_load 0.01 [get_ports {result[11]}]
set_load -pin_load 0.01 [get_ports {result[10]}]
set_load -pin_load 0.01 [get_ports {result[9]}]
set_load -pin_load 0.01 [get_ports {result[8]}]
set_load -pin_load 0.01 [get_ports {result[7]}]
set_load -pin_load 0.01 [get_ports {result[6]}]
set_load -pin_load 0.01 [get_ports {result[5]}]
set_load -pin_load 0.01 [get_ports {result[4]}]
set_load -pin_load 0.01 [get_ports {result[3]}]
set_load -pin_load 0.01 [get_ports {result[2]}]
set_load -pin_load 0.01 [get_ports {result[1]}]
set_load -pin_load 0.01 [get_ports {result[0]}]
create_clock [get_ports clk]  -period 5  -waveform {0 2.5}
set_clock_uncertainty 0.1  [get_clocks clk]
set_clock_transition -max -rise 0.1 [get_clocks clk]
set_clock_transition -max -fall 0.1 [get_clocks clk]
set_clock_transition -min -rise 0.1 [get_clocks clk]
set_clock_transition -min -fall 0.1 [get_clocks clk]
set_input_delay -clock clk  1.5  [get_ports LD_seed]
set_output_delay -clock clk  1.5  [get_ports {result[15]}]
set_output_delay -clock clk  1.5  [get_ports {result[14]}]
set_output_delay -clock clk  1.5  [get_ports {result[13]}]
set_output_delay -clock clk  1.5  [get_ports {result[12]}]
set_output_delay -clock clk  1.5  [get_ports {result[11]}]
set_output_delay -clock clk  1.5  [get_ports {result[10]}]
set_output_delay -clock clk  1.5  [get_ports {result[9]}]
set_output_delay -clock clk  1.5  [get_ports {result[8]}]
set_output_delay -clock clk  1.5  [get_ports {result[7]}]
set_output_delay -clock clk  1.5  [get_ports {result[6]}]
set_output_delay -clock clk  1.5  [get_ports {result[5]}]
set_output_delay -clock clk  1.5  [get_ports {result[4]}]
set_output_delay -clock clk  1.5  [get_ports {result[3]}]
set_output_delay -clock clk  1.5  [get_ports {result[2]}]
set_output_delay -clock clk  1.5  [get_ports {result[1]}]
set_output_delay -clock clk  1.5  [get_ports {result[0]}]
