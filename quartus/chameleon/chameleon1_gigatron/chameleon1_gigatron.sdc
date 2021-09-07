set_time_format -unit ns -decimal_places 3
create_clock -period 125.000 [get_ports {clk8m}]
derive_pll_clocks
