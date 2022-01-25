// Greg Stitt
// University of Florida
//

`timescale 1 ns / 100 ps

module monitor_tb;

   localparam int NUM_TESTS = 10000;
   localparam int DATA_WIDTH=8;
   localparam int COUNTER_WIDTH=64;
   
   logic 	  clk, rst, en, ready, count_valid;   
   logic [COUNTER_WIDTH-1:0] count;      
   int 			     correct_count=0;   
   
   monitor #(.DATA_WIDTH(DATA_WIDTH), .COUNTER_WIDTH(COUNTER_WIDTH)) DUT (.*);

   initial begin : generate_clock
      clk = 1'b0;
      while (1) #5 clk = ~clk;      
   end

   initial begin
      $timeformat(-9, 0, " ns");      
      
      // Reset the circuit.
      rst = 1'b1;
      en <= 1'b0;   
      for (int i=0; i < 5; i++) @(posedge clk);
      rst = 1'b0;
      @(posedge clk);
                  
      // Run the tests.      
      for (int i=0; i < NUM_TESTS; i++) begin
	 en = $random && ready;	 
	 @(posedge clk);
      end

      en = 1'b0;
      @(posedge clk);	 
      wait(count_valid);
      assert(count == correct_count);            
      $display("Tests completed.");      
      disable generate_clock;
   end

   always @(posedge clk) begin
      if (en && ready) correct_count ++;      
   end    
      
endmodule
