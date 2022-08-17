// Greg Stitt
// University of Florida
//
// This example illustrates how two semantically equivalent modules in terms
// of simulated behavior can synthesize into significantly different circuits
// with considerable area and timing differences.
//
// The module used in this example is synthetic, but is representative of
// functionality included in a variety of real circuits (e.g., FIFOs). The
// count module maintains an internal count based on the down and up control
// signals. Unlike a standard down/up counter, which can either count up or down
// in a given cycle, this count module can count up and down. Such functionality
// is often needed to track the number of elements in a buffer, pending data
// within a pipeline, etc.

// Module: count_slow
// Description: This module uses a straightforward, seemingly obvious 
// implementation that many designers would likely try on a first attempt.

// Resulting circuit:
// Slow 1200mV 85C Model Fmax: 230.79 MHz (FAILS)
// 33 logic elements

module count_slow
  #(parameter int WIDTH)
   (
    input logic 		    clk, rst, down, up,
    output logic signed [WIDTH-1:0] out
    );
   
   logic [WIDTH-1:0] 	     count_r;      
   assign out = count_r;

   // We purposely avoid an always_ff block since we will be using blocking
   // assignments.
   always @(posedge clk or posedge rst) begin
      if (rst) begin
	 count_r <= '0;
      end
      else begin
	 // If the up signal is asserted, increase the count.
	 // NOTE: ++ uses a blocking assignment, which we want here.
	 if (up) count_r ++;

	 // If down is asserted, decrease the count. Note that if the previous
	 // line incremented count_r, count_r will essentially stay the same
	 // if down is also asserted. While this may sound strange, such
	 // behavior occurs in a FIFO when reading and writing simultaneously.
	 if (down) count_r --;	 
      end
   end   

   // Explanation: the reason for the slow timing and resource overhead in this
   // implementation is that Quartus allocates a separate adder and subtractor
   // that are chained together. This creates a much longer critical path
   // through two adders. We optimize this below by creating a single adder
   // that adds by 0,1, or -1 with a mux. Although synthesis could potentially
   // make this optimization automatically, it does not for the version of
   // Quartus we tested.
   
endmodule // count_slow


// Module: count_fast
// Description: This module uses a less obvious implementation that synthesizes
// to a significantly smaller and faster circuit in Quartus. To improve the
// previous module, we explicitly use a single adder instead of a separate
// adder and subtractor. The single adder uses a mux that selects between 1, -1,
// and 0 depending on the status of down and up. Although a synthesis tool could
// potentially convert the count_slow module into this same logic, it appears
// that most synthesis tools do not. Therefore, the lesson here is that you
// sometimes have to force synthesis into a particular implementation.
//
// NOTE: This example might seem to suggest that synthesis simply allocates an
// adder for every instance of a + or - operation in the code. Although this
// is true for this example, it is not always true. The tutorial
// will include other examples that demonstrate exceptions. 

// Resulting circuit:
// Slow 1200mV 85C Model Fmax: 330.69 MHz
// 19 logic elements

module count_fast
  #(parameter int WIDTH)
   (
    input logic 		    clk, rst, down, up,
    output logic signed [WIDTH-1:0] out
    );

   logic [WIDTH-1:0] 	     count_r, count_update, count_next;      
   assign out = count_r;

   // Here we simply create a register for the count.
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 count_r <= '0;
      end
      else begin
	 count_r <= count_next;	 
      end
   end

   // Instead of having an adder and a subtractor, we can use a single adder
   // with a mux that selects between 1, -1, or 0 on the second input.
   always_comb begin
      // Create the mux that selects the second adder input.
      case ({up, down})
	2'b10 : count_update = WIDTH'(1);
	2'b01 : count_update = '1;  // Equivalent to -1
	default : count_update = '0;	
      endcase

      // Create the adder.
      count_next = count_r + count_update;
   end
endmodule


// Module: count
// Description: A top-level module for evaluating each implementation. Change
// the commented out implementation to synthesize each version.

module count
  #(parameter int WIDTH=16)
   (
    input logic 		    clk, rst, down, up,
    output logic signed [WIDTH-1:0] out
    );

   count_slow #(WIDTH) top (.*);
   //count_fast #(WIDTH) top (.*);
   
endmodule
