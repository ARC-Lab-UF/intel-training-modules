// Greg Stitt
// University of Florida
//
// TODO: Make sure the multiple_add_module at the bottom of the file is using
// the multiple_add_full_reset module. Then, compile the design, run the timing 
// analyzer, and identify the timing bottlenecks. Next, comment out the
// multiple_add_full_reset instantiation and uncomment multiple_add_min_reset.
// Repeat the same process as before and notice the change in clock
// frequency.
//
// NOTE: The resulting clock frequencies from my tested experiments are included
// but are likely to vary depending on your version of Quartus.
//

// Module Descriptions:  The following modules implement a simple pipeline with
// NUM_ADDERS parallel additions and a pipeline latency of 3 cycles. To help
// the user know when the output is valid, there is a valid_in signal, which
// the user asserts any time there is valid data. The module then asserts a
// valid_out signal anytime data leaving the module is valid.

//===================================================================
// Parameter Description
// DATA_WIDTH : The data width (number of bits) of the input and output
// NUM_ADDERS : The number of adds to perform.
//===================================================================

//===================================================================
// Interface Description
// clk  : Clock input
// rst  : Reset input (active high)
// in   : An DATA_WIDTH-bit input to add with different constants
// valid_in : User should assert any time the input data on "in" is valid.
// out  : An array of sums of in with different constants
// valid_out : The module asserts whenever "out" contains valid data.
//===================================================================


// Module: multiple_add_full_reset
// Description: This module implements the pipeline while resetting every
// register.

// Resulting clocks:
// Slow 1200mV 85C Model Fmax: 183.76 MHz (FAILS)
// Slow 1200mV 0C Model Fmax: 198.06 MHz (FAILS)

module multiple_add_full_reset
  #(parameter int DATA_WIDTH,
    parameter int NUM_ADDERS)
   (
    input logic 		  clk,
    input logic 		  rst,
    input logic [DATA_WIDTH-1:0]  in,
    input logic 		  valid_in,
    output logic [DATA_WIDTH-1:0] out[NUM_ADDERS],
    output logic 		  valid_out
    );

   localparam int 		  LATENCY = 3;
      
   logic [DATA_WIDTH-1:0] 	  in_r;
   logic [DATA_WIDTH-1:0] 	  add_in_r;
   logic [0:LATENCY-1] 		  valid_delay_r;
      
   // Simple pipeline that resets every register.
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
 	 in_r <= '0;
	 add_in_r <= '0;	 
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= '0;	 
      end
      else begin
	 in_r <= in;
	 add_in_r <= in_r;
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= add_in_r + DATA_WIDTH'(i);
      end
   end 

   // Delay that determines when out is valid based on the pipeline latency.
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 for (int i=0; i < LATENCY; i++) valid_delay_r[i] = '0;
      end
      else begin
	 valid_delay_r[0] <= valid_in;	 
	 for (int i=1; i < LATENCY; i++) valid_delay_r[i] <= valid_delay_r[i-1];
      end      
   end

   assign valid_out = valid_delay_r[LATENCY-1];   
endmodule


// Module: multiple_add_min_reset
// Description: Identical in functionality to the previous module, but only
// resets the delay registers needed for establishing the validity of the
// output.

// Resulting clocks:
// Slow 1200mV 85C Model Fmax: 200.88 MHz
// Slow 1200mV 0C Model Fmax: 218.29 MHz

module multiple_add_min_reset
  #(parameter int DATA_WIDTH,
    parameter int NUM_ADDERS)
   (
    input logic 		  clk,
    input logic 		  rst,
    input logic [DATA_WIDTH-1:0]  in,
    input logic 		  valid_in,
    output logic [DATA_WIDTH-1:0] out[NUM_ADDERS],
    output logic 		  valid_out
    );

   localparam int 		  LATENCY = 3;
      
   logic [DATA_WIDTH-1:0] 	  in_r;
   logic [DATA_WIDTH-1:0] 	  add_in_r;
   logic [0:LATENCY-1] 		  valid_delay_r;
      
   // We don't actually need a reset here because the user can just monitor the
   // valid_out signal to ignore any junk values, including those after reset.
   always_ff @(posedge clk) begin
      in_r <= in;
      add_in_r <= in_r;
      for (int i=0; i < NUM_ADDERS; i++) out[i] <= add_in_r + DATA_WIDTH'(i); 
   end 

   // We still have to reset the delay registers to make sure the outputs of the
   // pipeline are ignored after reset.
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 for (int i=0; i < LATENCY; i++) valid_delay_r[i] = '0;
      end
      else begin
	 valid_delay_r[0] <= valid_in;	 
	 for (int i=1; i < LATENCY; i++) valid_delay_r[i] <= valid_delay_r[i-1];
      end      
   end

   assign valid_out = valid_delay_r[LATENCY-1];   
endmodule


// Module: multiple_add
// Description: Provides a top-level module for synthesizing each 
// implementation. Simply uncomment the instantiation you want to test, and
// then recompile in Quartus.

module multiple_add
  #(parameter int DATA_WIDTH=32,
    parameter int NUM_ADDERS=64)
   (
    input logic 		  clk,
    input logic 		  rst,
    input logic [DATA_WIDTH-1:0]  in,
    input logic 		  valid_in,
    output logic [DATA_WIDTH-1:0] out[NUM_ADDERS],
    output logic 		  valid_out
    );

   multiple_add_full_reset #(.DATA_WIDTH(DATA_WIDTH), .NUM_ADDERS(NUM_ADDERS)) top (.*);
   //multiple_add_min_reset #(.DATA_WIDTH(DATA_WIDTH), .NUM_ADDERS(NUM_ADDERS)) top (.*); 
      
endmodule
