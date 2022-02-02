// Greg Stitt
// University of Florida
//
// Testbench for the count example.

`timescale 1 ns / 100 ps

module count_tb;

   localparam int NUM_TESTS = 10000;
   localparam int WIDTH = 16;
      
   logic 	  clk, rst, down, up;
   logic [WIDTH-1:0] out, correct_out;
         
   count #(.WIDTH(WIDTH)) DUT (.*);
   
   initial begin : generate_clock
      clk = 1'b0;
      while (1) #5 clk = ~clk;      
   end

   initial begin
      $timeformat(-9, 0, " ns");      
      
      // Reset the circuit.
      rst = 1'b1;
      down = 1'b0;
      up = 1'b0;      
      for (int i=0; i < 5; i++) @(posedge clk);
      rst = 1'b0;
            
      // Run the tests.      
      for (int i=0; i < NUM_TESTS; i++) begin
	 down <= $random;
	 up <= $random;	 
	 @(posedge clk);	 
      end

      $display("Tests completed.");      
      disable generate_clock;
   end

   // Track the correct output
   always_ff @(posedge clk or posedge rst)
     if (rst) correct_out <= '0;
     else begin
	case ({up, down})
	  2'b10 : correct_out ++;	 
	  2'b01 : correct_out --;
	endcase
     end

   // Verify the correct output.
   assert property(@(posedge clk) out == correct_out);
      
endmodule
