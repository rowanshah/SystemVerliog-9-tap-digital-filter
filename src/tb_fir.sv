 ////////////////////////////////////////////////////////////////////
 // tb_fir.sv
 // Philip Watts, 2nd Oct 2012
 // Department of Electronic and Electrical Engineering, UCL
 // v2.0
 //
 // A simple testbench for the fir9 module.    It can
 // be run within modelsim to view waveforms for debugging.  It is 
 // also called by MATLAB during the fir9 demo. Remember to add any
 // submodules which you write to the compile list below.
 //
 // To run within modelsim:
 // Open modelsim, change to the project directory, 
 // type 'do {fir.do}' at the command line. 
 // When asked 'do you want to finish', click no
 // Use +/- to zoom in/out
/////////////////////////////////////////////////////////////////////

module tb_fir();

  logic [3:0] s [0:1023];		// Stores 1024 4-bit signal values 
  int k, fid;
  logic clk, rst;
  logic [9:0] count;			// Counter to read signals sequentially into FIR
  logic y;				// 11 bit FIR filter output
  logic [3:0] c [0:8]; // Array of nine 5-bit filter coefficients
  logic [10:0] thresh;
  
  // Instantiate the module under test
  fir9 inst_fir (
	.y(y), 
	.thresh(thresh),
	.x(s[count]),
	.c(c),		
	.rst(rst), 
	.clk(clk));

  // Define the filter coefficients (fixed)
  initial begin
    c[0] = 1;
    c[1] = 3;
    c[2] = 8;
    c[3] = 13;
    c[4] = 15;
    c[5] = 13;
    c[6] = 8;
    c[7] = 3;
    c[8] = 1;
	thresh = 450;
  end 

  // Test bench operation	
  initial begin
    $readmemb("fir_in.txt", s);		// Read signal values into s
    fid = $fopen("fir_out.txt");	// Open a text file for output
    rst = 1;						// Start operation with reset high
    #(100ns)				
    rst = 0;						// Wait 100ns before reset goes low
	  #(128000ns);						// Run for 2 full pattern cycles
	  $fclose(fid); 					// Close output file
	  $finish;    					// End simulation
  end

 // Define the clock (period 10 ns)
  initial begin
    clk = 0;
    forever #5ns clk <= ~clk;
 end
 
// A counter to act as an address pointer to stored signal values 
// Write the FIR output to file each clock cycle 
  always_ff @(posedge clk, posedge rst)
	if (rst) begin
		count <= 0;
	end else begin
		count <= count + 1;
		$fdisplay(fid, "%d", y);
	end 

endmodule