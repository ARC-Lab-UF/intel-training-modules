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

// Module Name:  pipeline.sv
// Project:      simple pipeline
// Description:  This pipelines takes 16 32-bit unsigned inputs, multiplies 
//               each pair of inputs to generate 8 64-bit products, and then
//               adds those products to generate a 64-bit result (the adds 
//               ignore carries).
//
//               The pipeline has valid inputs when valid_in is asserted, and
//               asserts valid_out when the result is valid. The pipeline stalls
//               when en = 0, but recommended usage is to hardcode en to 1 when
//               instantiating the pipeline (see afu.sv).

//===================================================================
// Interface Description
// clk  : Clock input
// rst  : Reset input (active high)
// en   : Activates pipeline when asserted (active high), stalls when 0
// valid_id : Specifies validity of data on inputs.
// inputs : An array of 16 unsigned 32-bit inputs.
// result : The 64-bit result.
// valid_out : Asserted when result contains valid data (active high)
//===================================================================

module pipeline
  (
    input 		clk,
    input 		rst,
    input 		en, 
    input 		valid_in,
    input [31:0] 	inputs[16],
    output logic [63:0] result,
    output logic 	valid_out
    );

   // Would normally be calculated based off the number of inputs, but since
   // the inputs are fixed, the latency is just hardcoded.
   localparam int 	LATENCY = 5;

   // Signals for each row of the multiply-add tree.
   logic [31:0] 		   inputs_r[16];
   logic [63:0] 		   mult_out_r[8];
   logic [63:0] 		   add_out_l1_r[4];
   logic [63:0] 		   add_out_l2_r[2];

   // Delays valid_in by LATENCY cycles.
   logic 			   delay_r[LATENCY];  
 
   // Create a pipelined multiply-add tree.
   always_ff @ (posedge clk or posedge rst) begin

      if (rst) begin
	 // Although it is ok to reset all the internal pipeline registers, I
	 // recommend against it since it creates a huge fan-out on the reset 
	 // signal. However, the delay must be reset to avoid valid_out being
	 // asserted incorrectly.
	 for (int i=0; i < LATENCY; i++) begin
	    delay_r[i] <= 1'b0;	    
	 end
      end
      
      // The enable stalls the pipeline. Whenever possible, avoid using a 
      // stall signal. It is perfectly fine (and recommended) to create a
      // pipeline with an enable so that it can be used in any context, but
      // when instantiating the pipeline, it is best to set the enable to 1
      // whenever possible so it synthesizes away. See afu.sv for more
      // information.
      else if (en) begin
	 // Register the inputs (not necessary, but usually a good idea
	 // for timing optimization if you don't know where they come from).
	 for (int i=0; i < 16; i++) begin
	    inputs_r[i] <= inputs[i];  	    
	 end

	 // Multiply pairs of inputs.
	 for (int i=0; i < 8; i++) begin
	    mult_out_r[i] <= inputs_r[i*2] * inputs_r[i*2+1];
	 end;

	 // Add pairs of multiplication outputs.
	 for (int i=0; i < 4; i++) begin
	    add_out_l1_r[i] <= mult_out_r[i*2] + mult_out_r[i*2+1];
	 end;

	 // Add pairs of previous adds.
	 for (int i=0; i < 2; i++) begin
	    add_out_l2_r[i] <= add_out_l1_r[i*2] + add_out_l1_r[i*2+1];
	 end;

	 // Add the final two adder outputs to get the result.
	 result <= add_out_l2_r[0] + add_out_l2_r[1];

	 // Delay valid_in by LATENCY cycles.
	 delay_r[0] <= valid_in;	 
	 for (int i=1; i < LATENCY; i++) begin
	    delay_r[i] <= delay_r[i-1];	    
	 end
      end     
   end

   // The pipeline output is valid after LATENCY cycles (with enable asserted).
   assign valid_out = delay_r[LATENCY-1];      

endmodule

   
   
