set_time_format -unit ns -decimal_places 3

create_clock -name {clk_i} -period 20.00 -waveform {0.000 10.00} [get_ports {clk_i}]
derive_pll_clocks