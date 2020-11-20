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
// along with this program.  If not, see <https://www.gnu.org/licenses/>

// Greg Stitt
// University of Florida

// Module Name:  add_tree.sv
// Description:  This module adds 8 WIDTH-bit inputs using an adder tree, where
// to produce a WIDTH-bit output. All overflow is ignored.
//
// This implementation solves the timing bottleneck of the unoptimized code
// by adding registers to the output of every adder in the adder tree.

//===================================================================
// Parameter Description
// WIDTH : The data width (number of bits) of the inputs and output
//===================================================================

//===================================================================
// Interface Description
// clk  : Clock input
// rst  : Reset input (active high)
// inputs : An array of 8 WIDTH-bit inputs to add
// sum : A single WIDTH-bit output that represents the sum of inputs
//===================================================================

module add_tree #(parameter int WIDTH=16)		   		  
  (
   input 		    clk, 
   input 		    rst,
   input        [WIDTH-1:0] inputs[8],
   output logic [WIDTH-1:0] sum
   );

   logic [WIDTH-1:0] 	    inputs_r[$size(inputs)];
   logic [WIDTH-1:0] 	    add0_0, add0_1, add0_2, add0_3;
   logic [WIDTH-1:0] 	    add1_0, add1_1, add2_0;

   always_ff @(posedge clk or posedge rst) begin

      if (rst) begin
	 // Reset the input registers
	 for (int i=0; i < 8; i++) begin
	    inputs_r[i] <= 0;	    
	 end

	 // Reset the output register
	 sum <= 0;
	 
      end else begin

	 // Register the inputs
	 inputs_r <= inputs;

	 // Register the first row of adders 
	 add0_0 <= inputs_r[0] + inputs_r[1];
	 add0_1 <= inputs_r[2] + inputs_r[3];
	 add0_2 <= inputs_r[4] + inputs_r[5];
	 add0_3 <= inputs_r[6] + inputs_r[7];

	 // Register the second row of adders
	 add1_0 <= add0_0 + add0_1;
	 add1_1 <= add0_2 + add0_3;

	 // Final adder (blocking assignment of add2_0 prevents an extra 
	 // register on the output)
	 add2_0 = add1_0 + add1_1;
	 sum   <= add2_0;	 
      end 
   end // always_ff @

endmodule
