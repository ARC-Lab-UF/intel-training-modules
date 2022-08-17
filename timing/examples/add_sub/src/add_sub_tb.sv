// Greg Stitt
// University of Florida
//
// Testbench for the add_sub example.

`timescale 1 ns / 100 ps

module add_sub_tb;

   localparam int NUM_TESTS = 10000;
   localparam int WIDTH = 16;

   logic 	  sel;   
   logic [WIDTH-1:0] in0, in1, out, correct_out;
         
   add_sub #(.WIDTH(WIDTH)) DUT (.*);

   function logic [WIDTH-1:0] model();
      if (sel) return in0 - in1;
      return in0 + in1;      
   endfunction
   
   initial begin
      $timeformat(-9, 0, " ns");      
                  
      // Run the tests.      
      for (int i=0; i < NUM_TESTS; i++) begin
	 sel = $random;	 
	 in0 = $random;
	 in1 = $random;
	 #10;
	 assert(out == model());	 
      end

      $display("Tests completed.");      
   end
      
endmodule
