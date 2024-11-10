## Generated SDC file "C:/projects/UARTP/sdc/main.sdc"

## Copyright (C) 2024  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and any partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details, at
## https://fpgasoftware.intel.com/eula.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 23.1std.1 Build 993 05/14/2024 SC Lite Edition"

## DATE    "Sun Nov 10 12:22:36 2024"

##
## DEVICE  "10CL025YU256A7G"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {altera_reserved_tck} -period 100.000 -waveform { 0.000 50.000 } [get_ports {altera_reserved_tck}]
create_clock -name {clk_i} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clk_i}]


#**************************************************************
# Create Generated Clock
#**************************************************************

#create_generated_clock -name {pll_60o} -source [get_ports {clk_i}] -multiply_by 6 -divide_by 5 -master_clock {clk_i} 
create_generated_clock -name {pll_60o} -source [get_pins {u1|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 6 -divide_by 5 -master_clock {clk_i} [get_pins {u1|altpll_component|auto_generated|pll1|clk[0]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -add_delay -max -clock [get_clocks {pll_60o}]  1.350 [get_ports {altera_reserved_tck}]
set_input_delay -add_delay -max -clock [get_clocks {pll_60o}]  1.350 [get_ports {altera_reserved_tdi}]
set_input_delay -add_delay -max -clock [get_clocks {pll_60o}]  1.350 [get_ports {altera_reserved_tms}]
set_input_delay -add_delay -max -clock [get_clocks {pll_60o}]  1.350 [get_ports {btn[0]}]
set_input_delay -add_delay -max -clock [get_clocks {pll_60o}]  1.350 [get_ports {btn[1]}]
set_input_delay -add_delay -max -clock [get_clocks {pll_60o}]  1.350 [get_ports {clk_i}]
set_input_delay -add_delay -max -clock [get_clocks {pll_60o}]  1.350 [get_ports {gpio[0]}]
set_input_delay -add_delay -max -clock [get_clocks {pll_60o}]  1.350 [get_ports {gpio[1]}]
set_input_delay -add_delay -max -clock [get_clocks {pll_60o}]  1.350 [get_ports {rx}]


#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -add_delay  -clock [get_clocks {pll_60o}]  1.700 [get_ports {altera_reserved_tdo}]
set_output_delay -add_delay  -clock [get_clocks {pll_60o}]  1.700 [get_ports {data_led[0]}]
set_output_delay -add_delay  -clock [get_clocks {pll_60o}]  1.700 [get_ports {data_led[1]}]
set_output_delay -add_delay  -clock [get_clocks {pll_60o}]  1.700 [get_ports {data_led[2]}]
set_output_delay -add_delay  -clock [get_clocks {pll_60o}]  1.700 [get_ports {data_led[3]}]
set_output_delay -add_delay  -clock [get_clocks {pll_60o}]  1.700 [get_ports {data_led[4]}]
set_output_delay -add_delay  -clock [get_clocks {pll_60o}]  1.700 [get_ports {data_led[5]}]
set_output_delay -add_delay  -clock [get_clocks {pll_60o}]  1.700 [get_ports {data_led[6]}]
set_output_delay -add_delay  -clock [get_clocks {pll_60o}]  1.700 [get_ports {data_led[7]}]
set_output_delay -add_delay  -clock [get_clocks {pll_60o}]  1.700 [get_ports {gpio[0]}]
set_output_delay -add_delay  -clock [get_clocks {pll_60o}]  1.700 [get_ports {gpio[1]}]
set_output_delay -add_delay  -clock [get_clocks {pll_60o}]  1.700 [get_ports {led}]
set_output_delay -add_delay  -clock [get_clocks {pll_60o}]  1.700 [get_ports {led2}]
set_output_delay -add_delay  -clock [get_clocks {pll_60o}]  1.700 [get_ports {led3}]
set_output_delay -add_delay  -clock [get_clocks {pll_60o}]  1.700 [get_ports {led4}]
set_output_delay -add_delay  -clock [get_clocks {pll_60o}]  1.700 [get_ports {tx}]


#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 


#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

