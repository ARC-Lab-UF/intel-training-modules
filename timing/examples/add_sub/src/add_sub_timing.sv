// Greg Stitt
// University of Florida

// Module: add_sub_timing
// Description: Top-level used for timing analysis. The add_sub module is
// combinational, so we wrap it in this module with registered I/O to enable
// timing analysis.
//
// IMPORTANT: Do not use this module for collecting resource counts since it
// adds in extra ALMs for the registers.

module add_sub_timing
  #(parameter int WIDTH=32)
   (
    input logic 	     clk, rst,
    input logic [WIDTH-1:0]  in0, in1,
    input logic 	     sel,
    output logic [WIDTH-1:0] out
    );

   logic [WIDTH-1:0] 	     in0_r, in1_r, out_r, out_s;
   logic 		     sel_r;

   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 in0_r <= '0;
	 in1_r <= '0;
	 sel_r <= '0;
	 out_r <= '0;	 
      end
      else begin
	 in0_r <= in0;
	 in1_r <= in1;
	 sel_r <= sel;
	 out_r <= out_s;	 
      end      
   end

   assign out = out_r;
      
   // Only provided for convenience to get the adder resource count.
   add_sub #(.WIDTH(WIDTH)) top (.in0(in0_r), .in1(in1_r), .sel(sel_r), .out(out_s));
         
endmodule
