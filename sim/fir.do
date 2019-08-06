 ##################################################################
 ## fir.do
 ## Philip Watts, 18th July 2011
 ## Department of Electronic and Electrical Engineering, UCL
 ##
 ## A modelsim script which simulates the 'fir9' design.  It can
 ## be run within modelsim to view waveforms for debugging.  It is 
 ## also called by MATLAB during the fir9 demo. Remember to add any
 ## submodules which you write to the compile list below.
 ##
 ## To run within modelsim:
 ## Open modelsim, change to the project directory, 
 ## type 'do {fir.do}' at the command line. 
 ## When asked 'do you want to finish', click no
 ## Use +/- to zoom in/out
 ##################################################################
 
 
 # Setup simulation library
 vlib work

 # Compile SystemVerilog files
 #vlog my_file.sv (list any submodules which you write within 'fir9.sv' here)
 vlog ../src/fir9.sv
 vlog ../src/tb_fir.sv
 
 # Start the simulation with the test bench as top module
 # and 1 ps time resolution
 vsim -t 1ps tb_fir
 
 # Set up the wave window to view signals
 # (This will not happen if you run modelesim from within MATLAB) 
 view wave 
 do wave.do

 # Run the simulation to completion 
 run -all
 
