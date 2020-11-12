// Copyright (c) 2020 University of Florida
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Greg Stitt
// University of Florida

// Module Name:  timer.sv
// Description:  This module provides a timer that counts a specified number
// of cycles, asserts an output, and then repeats indefinitely.

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
	 count_r <= count_r - 1'b1;
	
	 if (load == 1'b1) begin
	    cycles_r <= cycles;
	    count_r  <= cycles;	    
	 end

	 // By counting down from cycles_r to 0, this comparator now has
	 // half the number of logic inputs, which reduces the depth of the
	 // LUT hiearachy.
	 if (count_r == '0) begin
	    count_r <= cycles_r;
	    elapsed <= 1'b1;	    
	 end
      end
   end

endmodule
