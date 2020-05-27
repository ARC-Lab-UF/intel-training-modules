

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

   localparam int 	LATENCY = 5;
  
   logic [31:0] 		   inputs_r[16];
   logic [63:0] 		   mult_out_r[8];
   logic [63:0] 		   add_out_l1_r[4];
   logic [63:0] 		   add_out_l2_r[2];
   logic 			   delay_r[LATENCY];  
 
   // Create a pipelined multiply-accumulate tree.
   always_ff @ (posedge clk) begin

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
      // whenever possible so it synthesizes away.
      else if (en) begin
	 // Register the inputs (not necessary, but usually a good idea
	 // for timing optimization.
	 for (int i=0; i < 16; i++) begin
	    inputs_r[i] <= inputs[i];  	    
	 end

	 // Multiply pairs of inputs.
	 for (int i=0; i < 8; i++) begin
	    mult_out_r[i] <= inputs_r[i*2] * inputs_r[i*2+1];
	 end;

	 // Add pairs of multiplication outputs.
	 for (int i=0; i < 4; i++) begin
	    add_out_l1_r[i] <= mult_out_r[i*2] * mult_out_r[i*2+1];
	 end;

	 // Add pairs of previous adds.
	 for (int i=0; i < 2; i++) begin
	    add_out_l2_r[i] <= add_out_l1_r[i*2] * add_out_l1_r[i*2+1];
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

   
   
