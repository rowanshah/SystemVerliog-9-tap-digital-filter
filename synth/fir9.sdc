set_time_format -unit ns

#Specify the clock period
set period 10.000

# Set the clock input to 10ns period
create_clock -period $period -name clk [get_ports clk]


