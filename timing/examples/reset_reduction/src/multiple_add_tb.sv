// Greg Stitt
// University of Florida
//
// Simple testbench to verify the multiple_add module.

`timescale 1 ns / 100 ps

module multiple_add_tb;

   localparam int NUM_TESTS = 10000;
   localparam DATA_WIDTH = 8;
   localparam NUM_ADDERS = 4;
   
   logic 	  clk, rst, valid_in, valid_out;
   logic [DATA_WIDTH-1:0] in;
   logic [DATA_WIDTH-1:0] out[NUM_ADDERS];
   
   multiple_add #(.DATA_WIDTH(DATA_WIDTH), .NUM_ADDERS(NUM_ADDERS)) DUT (.*);

   initial begin : generate_clock
      clk = 1'b0;
      while (1) #5 clk = ~clk;      
   end

   initial begin
      $timeformat(-9, 0, " ns");
      rst <= 1'b1;
      valid_in <= 1'b0;
      in <= '0;
      for (int i=0; i < 5; i++) @(posedge clk);
      rst <= 1'b0;
      @(posedge clk);
                  
      for (int i=0; i < NUM_TESTS; i++) begin
	 in <= $random;
	 valid_in <= $random;
	 @(posedge clk);
      end

      $display("Tests completed.");      
      disable generate_clock;
   end

   // Track the number of valid elements in the pipeline.
   int count;    
   always_ff @(posedge clk or posedge rst)
     if (rst) count = 0;
     else if (count < DUT.top.LATENCY) count ++;

   // Reference model for the pipeline.
   function automatic logic is_out_correct(logic [DATA_WIDTH-1:0] in, logic [DATA_WIDTH-1:0] out[NUM_ADDERS]);
           
      for (int i=0; i < NUM_ADDERS; i++) begin
	 if (out[i] != in + DATA_WIDTH'(i)) return 1'b0;	 
      end
      return 1'b1;    
   endfunction

   // Make sure the output is correct.
   assert property (@(posedge clk) disable iff (rst) count == DUT.top.LATENCY |-> is_out_correct($past(in, DUT.top.LATENCY), out));

   // Make sure the valid output is not asserted after reset until the pipeline
   // fills up.
   assert property (@(posedge clk) disable iff (rst) count < DUT.top.LATENCY |-> valid_out == '0);

   // Make sure valid out is asserted at the right times.
   assert property (@(posedge clk) disable iff (rst) valid_in |-> ##[DUT.top.LATENCY:DUT.top.LATENCY] valid_out);
         
endmodule
