// Greg Stitt
// University of Florida

// Module: adder_3input_timing
// Description: Top-level used for timing analysis. The adder_3input module is
// combinational, so we wrap it in this module with registered I/O to enable
// timing analysis.
//
// IMPORTANT: Do not use this module for collecting resource counts since it
// adds in extra ALMs for the registers. It should only be used for timing
// analysis.

module adder_3input_timing
  #(parameter int WIDTH=16)
   (
    input logic clk, rst,
    input logic [WIDTH-1:0]  in0, in1, in2,
    output logic [WIDTH-1:0] out
    );

   logic [WIDTH-1:0] 	     in0_r, in1_r, in2_r, out_r, out_s;
   
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 in0_r <= '0;
	 in1_r <= '0;
	 in2_r <= '0;
	 out_r <= '0;	 
      end
      else begin
	 in0_r <= in0;
	 in1_r <= in1;
	 in2_r <= in2;
	 out_r <= out_s;	 
      end
   end
   
   assign out = out_r;

   adder_3input #(.WIDTH(WIDTH)) top (.in0(in0_r), .in1(in1_r), .in2(in2_r), .out(out_s));
         
endmodule
