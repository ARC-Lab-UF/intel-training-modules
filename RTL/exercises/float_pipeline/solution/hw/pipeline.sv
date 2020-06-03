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
// Description:  This pipelines takes 16 32-bit floats, multiplies 
//               each pair of inputs to generate 8 32-bit float products, and 
//               then adds those products to generate a 32-bit float result.
//               All operations use 32-bit floats.
//
//               The pipeline implements the functionality as a complete
//               multiply-add tree in order to imitate the simple_pipeline
//               example. Although this works, it does not provide the most
//               effective usage of DSP resources. A DSP can be configured
//               to perform a multiply and and add, which would save DSPs here.
//               However, when doing a multiply and add, the DSP has some
//               restrictions on circuit structure, which requires additional
//               delays. It is left as an exercise to the reader to implement
//               the same design with DSPs performing a multiply and add.
//
//               The pipeline has valid inputs when valid_in is asserted, and
//               asserts valid_out when the result is valid. The pipeline stalls
//               when en = 0, but recommended usage is to hardcode en to 1 when
//               instantiating the pipeline (see afu.sv).
//
//               The latency of the floating point operations and the total
//               pipeline is specified in pipe_pkg.sv.


import pipe_pkg::*;

//===================================================================
// Interface Description
// clk  : Clock input
// rst  : Reset input (active high)
// en   : Activates pipeline when asserted (active high), stalls when 0
// valid_id : Specifies validity of data on inputs.
// inputs : An array of 16 32-bit float inputs.
// result : The 32-bit float result.
// valid_out : Asserted when result contains valid data (active high)
//===================================================================

module pipeline
  (
    input 		clk,
    input 		rst,
    input 		en, 
    input 		valid_in,
    input [31:0] 	inputs[16],
    output logic [31:0] result,
    output logic 	valid_out
    );

   // Signals for each row of the multiply-add tree.
   logic [31:0] 		   inputs_r[16];
   logic [31:0] 		   mult_out[8];
   logic [31:0] 		   add_out_l1[4];
   logic [31:0] 		   add_out_l2[2];

   // Delays valid_in by pipe_pkg::PIPE_LATENCY cycles.
   logic 			   delay_r[pipe_pkg::PIPE_LATENCY];

   genvar 			   i;

   // Generate the 8 multipliers.
   generate
      for (i=0; i < 8; i++) begin : gen_mults
	 mult_float mult (
			.a(inputs_r[2*i]),
			.areset(rst),
			.b(inputs_r[2*i+1]),
			.clk(clk),
			.en(en),
			.q(mult_out[i])
			);
      end
   endgenerate

   // Generate the first level of adders to add the 4 multiplier outputs.
   generate
      for (i=0; i < 4; i++) begin : gen_add_l1
	 add_float add_l1 (
			.a(mult_out[2*i]),
			.areset(rst),
			.b(mult_out[2*i+1]),
			.clk(clk),
			.en(en),
			.q(add_out_l1[i])
			);
      end
   endgenerate

   // Generate the second level of adders to add the 2 level 1 adder outputs.
   generate
      for (i=0; i < 2; i++) begin : gen_add_l2
	 add_float add_l2 (
			.a(add_out_l1[2*i]),
			.areset(rst),
			.b(add_out_l1[2*i+1]),
			.clk(clk),
			.en(en),
			.q(add_out_l2[i])
			);
      end
   endgenerate

   // Instantiate the final adder to generate the result.
   add_float add_l3 (
		     .a(add_out_l2[0]),
		     .areset(rst),
		     .b(add_out_l2[1]),
		     .clk(clk),
		     .en(en),
		     .q(result)
		     );
      
   // Create a pipelined multiply-add tree.
   always_ff @ (posedge clk or posedge rst) begin

      if (rst) begin
	 // Although it is ok to reset all the internal pipeline registers, I
	 // recommend against it since it creates a huge fan-out on the reset 
	 // signal. However, the delay must be reset to avoid valid_out being
	 // asserted incorrectly.
	 for (int i=0; i < pipe_pkg::PIPE_LATENCY; i++) begin
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

	 // Delay valid_in by pipe_pkg::PIPE_LATENCY cycles.
	 delay_r[0] <= valid_in;	 
	 for (int i=1; i < pipe_pkg::PIPE_LATENCY; i++) begin
	    delay_r[i] <= delay_r[i-1];	    
	 end
      end     
   end

   // The pipeline output is valid after pipe_pkg::PIPE_LATENCY cycles (with enable asserted).
   assign valid_out = delay_r[pipe_pkg::PIPE_LATENCY-1]; 

endmodule

   
   
