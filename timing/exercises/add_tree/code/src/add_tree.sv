// Module Name:  add_tree.sv
// Description:  This module adds 8 WIDTH-bit inputs using an adder tree, where
// to produce a WIDTH-bit output. All overflow is ignored. 

// TODO: Compile the design, run the timing analyzer, and identify the timing
// bottlenecks. Then, pipeline the corresponding bottleneck to meet the 
// specified timing constraint.

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

	 // Register the inputs and output (required for timing analysis).
	 inputs_r <= inputs;
	 sum      <= add2_0;
      end 
   end

   // Implement the adder tree as combinational logic.
   always_comb begin
      // First row of adders (add the pairs of registered inputs)
      add0_0 = inputs_r[0] + inputs_r[1];
      add0_1 = inputs_r[2] + inputs_r[3];
      add0_2 = inputs_r[4] + inputs_r[5];
      add0_3 = inputs_r[6] + inputs_r[7];

      // Second row of adders
      add1_0 = add0_0 + add0_1;
      add1_1 = add0_2 + add0_3;

      // Final adder
      add2_0 = add1_0 + add1_1;           
   end

endmodule
