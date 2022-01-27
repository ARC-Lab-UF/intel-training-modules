// Greg Stitt
// University of Florida
//
// This example illustrates a multicycle path optimization. See
// multicycle_paths.pptx for an explanation. 
//
// The basic architecure consists of two adders, with one twice as wide as the 
// other. The wide adder is the critical path, which we address with a 
// multicycle path.
//
// TODO: Compile the multicycle_path module, run timing analysis to identify
// the WIDTH-bit adder bottleneck. Next, change the multicycle_path module to
// use the optimized module, recompile, and verify the improvement in clock
// frequency.

// Module: optimized
// Description: This module implements a 2-cycle path for the WIDTH-bit adder
// as opposed to the unoptimized module that uses single cycle paths.

module optimized
  #(
    parameter int WIDTH
    )
   (
    input logic 	       clk,
    input logic 	       rst, 
    input logic 	       en,
    input logic [WIDTH/2-1:0]  in0, in1,
    input logic [WIDTH-1:0]    in2, in3,
    output logic [WIDTH/2-1:0] out0,
    output logic [WIDTH-1:0]   out1
    );

   logic [WIDTH/2-1:0] 	       in0_r, in1_r, out0_r;
   logic [WIDTH-1:0] 	       in2_r, in3_r, out1_r;
   logic 		       en0_r, en1_r;

   assign out0 = out0_r;
   assign out1 = out1_r;
      
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 in0_r <= '0;
	 in1_r <= '0;
	 in2_r <= '0;
	 in3_r <= '0;	 
	 out0_r <= '0;	 
	 out1_r <= '0;
	 en0_r <= 1'b1;
	 en1_r <= 1'b1;	 
      end
      else begin	 
	 // Register the inputs
	 in0_r <= in0;
	 in1_r <= in1;	 	 
	 if (en) begin
	    in2_r <= in2;
	    in3_r <= in3;
	 end

	 // Create the delayed enable
	 en0_r <= en;
	 en1_r <= en0_r;

	 // Assign the outputs
	 out0_r <= in0_r + in1_r;	 
	 if (en1_r) out1_r <= in2_r + in3_r;
      end
   end // always_ff @

endmodule


// Module: unoptimized
// Description: A straightfoward single-cycle implementation of the two adds.

module unoptimized
  #(
    parameter int WIDTH
    )
   (
    input logic 	       clk,
    input logic 	       rst, 
    input logic 	       en,
    input logic [WIDTH/2-1:0]  in0, in1,
    input logic [WIDTH-1:0]    in2, in3,
    output logic [WIDTH/2-1:0] out0,
    output logic [WIDTH-1:0]   out1
    );

   logic [WIDTH/2-1:0] 	       in0_r, in1_r, out0_r;
   logic [WIDTH-1:0] 	       in2_r, in3_r, out1_r;
   
   assign out0 = out0_r;
   assign out1 = out1_r;
      
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 in0_r <= '0;
	 in1_r <= '0;
	 in2_r <= '0;
	 in3_r <= '0;	 
	 out0_r <= '0;	 
	 out1_r <= '0;	 
      end
      else begin	 
	 in0_r <= in0;
	 in1_r <= in1;	 	 
	 in2_r <= in2;
	 in3_r <= in3;
	 out0_r <= in0_r + in1_r;	 
	 out1_r <= in2_r + in3_r;
      end
   end // always_ff @

endmodule


// Module: multicycle_path
// Description: A top-level module for evaluating each implementation. Change
// the commented out implementation to synthesize each version.

module multicycle_path
  #(
    parameter int WIDTH=64
    )
   (
    input logic 	       clk,
    input logic 	       rst, 
    input logic 	       en,
    input logic [WIDTH/2-1:0]  in0, in1,
    input logic [WIDTH-1:0]    in2, in3,
    output logic [WIDTH/2-1:0] out0,
    output logic [WIDTH-1:0]   out1
    );

   unoptimized #(.WIDTH(WIDTH)) top (.*);
   //optimized #(.WIDTH(WIDTH)) top (.*);
      
endmodule
