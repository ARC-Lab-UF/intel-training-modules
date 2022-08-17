// Greg Stitt
// University of Florida
//
// Testbench for the replicated pipeline example.

`timescale 1 ns / 100 ps

module replicated_pipeline_tb;

   localparam int NUM_TESTS = 10000;
   localparam int WIDTH = 8;

   // NOTE: The reset tree module is hardcoded for 8 replications.
   localparam int NUM_REPLICATIONS = 8;
      
   logic 	  clk, rst, valid_in, valid_out;
   logic [WIDTH-1:0] in[NUM_REPLICATIONS];
   logic [4*WIDTH-1:0] out[NUM_REPLICATIONS];

   logic 	       output_ready;
      
   replicated_pipeline #(.WIDTH(WIDTH), .NUM_REPLICATIONS(NUM_REPLICATIONS)) DUT (.*);

   initial begin : generate_clock
      clk = 1'b0;
      while (1) #5 clk = ~clk;      
   end

   initial begin
      $timeformat(-9, 0, " ns");      
      output_ready = 1'b0;
      
      // Reset the circuit.
      rst = 1'b1;
      valid_in <= 1'b0;
      for (int i=0; i < NUM_REPLICATIONS; i++) in[i] <= '0;
      for (int i=0; i < 5; i++) @(posedge clk);
      rst = 1'b0;
      // We need to wait a sufficient amount of time for the reset tree
      // latency. This is one of the risks of using a reset tree because the
      // circuit must contain control that restricts usage during this latency.
      for (int i=0; i < 10; i++) @(posedge clk);     
      output_ready = 1'b1;
            
      // Run the tests.      
      for (int i=0; i < NUM_TESTS; i++) begin
	 for (int j=0; i < NUM_REPLICATIONS; i++) in[j] = $random;
	 valid_in <= $random;
	 @(posedge clk);
      end

      $display("Tests completed.");      
      disable generate_clock;
   end

   // Reference model.
   function automatic logic [4*WIDTH-1:0] model(logic [WIDTH-1:0] in);
      return 10 * (in**3) + 20 * (in**2) + 30*in + 40;            
   endfunction

   // Verify the outputs are correct.
   function automatic logic is_out_correct(logic [WIDTH-1:0] in[NUM_REPLICATIONS], logic [4*WIDTH-1:0] out[NUM_REPLICATIONS]);
      for (int i=0; i < NUM_REPLICATIONS; i++) begin       	 
	 if (out[i] != model(in[i])) return 1'b0;
      end
      
      return 1'b1;      
   endfunction
   
   // Track the amount of pipeline stages that are full.
   int count;    
   always_ff @(posedge clk or posedge rst)
     if (rst) count = 0;
     else if (count < DUT.LATENCY) count ++;
   
   assert property(@(posedge clk) disable iff (rst) output_ready |-> is_out_correct($past(in, DUT.LATENCY), out));
   
   // Make sure the valid output is not asserted after reset until the pipeline
   // fills up.
   assert property (@(posedge clk) disable iff (rst) count < DUT.LATENCY |-> valid_out == '0);
   
endmodule
