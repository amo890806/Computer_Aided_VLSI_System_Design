set_clock_latency -source -early -max -rise  -0.310894 [get_ports {i_clk}] -clock i_clk 
set_clock_latency -source -early -max -fall  -0.363871 [get_ports {i_clk}] -clock i_clk 
set_clock_latency -source -late -max -rise  -0.310894 [get_ports {i_clk}] -clock i_clk 
set_clock_latency -source -late -max -fall  -0.363871 [get_ports {i_clk}] -clock i_clk 
