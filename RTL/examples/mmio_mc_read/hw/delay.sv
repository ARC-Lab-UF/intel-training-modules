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

// Module Name:  delay.sv
// Description:  Delays an input signal by a specified number of cycles.

//===================================================================
// Parameter Description
// CYCLES   : The number of cycles to delay the input. Must be positive.
// WIDTH    : The number of bits in the input and output signal being delayed.
// INIT_VAL : An initialization value to use on reset for each internal
//            register of the delay.
//===================================================================

//===================================================================
// Interface Description
// clk  : Clock input
// rst  : Reset (active high)
// en : Enable (active high), 0 stalls the delay
// data_in : Input to be delayed
// data_out : The input after CYCLES cycles pass (assuming no stalls from en=0)
//===================================================================

module delay
  #(
    parameter int 		CYCLES,
    parameter int 		WIDTH,
    parameter logic [WIDTH-1:0] INIT_VAL = 0    
    )
   (
    input 		     clk,
    input logic 	     rst,
    input logic 	     en,
    input [WIDTH-1:0] 	     data_in,
    output logic [WIDTH-1:0] data_out
    );

   generate
      if (CYCLES == 0) begin
	 assign data_out = data_in;
      end
      else if (CYCLES > 0) begin
	 
	 logic [WIDTH-1:0] regs[CYCLES];
	 
	 always_ff @(posedge clk or posedge rst) begin
	    if (rst) begin
	       for (int i=0; i < CYCLES; i++) 
		 regs[i] <= INIT_VAL;		 
	    end
	    else begin
	       if (en) begin
		  regs[0] <= data_in;
		  for (int i=0; i < CYCLES-1; i++) 
		    regs[i+1] <= regs[i];
	       end
	    end
	 end
	 
	 assign data_out = regs[CYCLES-1];
      end
      else begin
	 initial
	   $error("Delay CYCLES parameter (%0d) must have positive value.", CYCLES);	    
      end
   endgenerate
   
endmodule
