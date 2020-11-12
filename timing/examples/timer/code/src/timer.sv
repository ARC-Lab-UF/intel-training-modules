// Module Name:  timer.sv
// Description:  This module provides a timer that counts a specified number
// of cycles, asserts an output, and then repeats indefinitely.

// TODO: Compile the design, run the timing analyzer, and identify the timing
// bottleneck in the comparison. Then, simplify the comparator by counting
// from cycles down to 0, instead of from 0 to cycles.

//===================================================================
// Parameter Description
// WIDTH : The data width (number of bits) of the cycles input.
//===================================================================

//===================================================================
// Interface Description
// clk  : Clock input
// rst  : Reset input (active high)
// load : Asserted to load a cycles value (active high)
// cycles : The number of cycles to count before asserting the output
// elasped : Asserted for 1-cycle after "cycles" cycles have elapsed
//===================================================================

module timer #(parameter int WIDTH=16)		   		  
  (
   input logic 	     clk,
   input logic 	     rst,
   input logic       load,
   input [WIDTH-1:0] cycles,
   output logic      elapsed
   );

   logic [WIDTH-1:0] count_r, cycles_r;
   
   always_ff @(posedge clk or posedge rst) begin

      if (rst) begin	 	 
	 count_r  <= '0;
	 cycles_r <= '0;
	 	 	 	 
      end else begin
	 
	 elapsed <= 1'b0;
	 count_r <= count_r + 1'b1;
	
	 if (load == 1'b1) begin
	    cycles_r <= cycles;
	    count_r  <= '0;	    
	 end

	 if (count_r == cycles_r) begin
	    count_r <= '0;
	    elapsed <= 1'b1;	    
	 end
      end
   end

endmodule
