// Greg Stitt
// University of Florida
//
// This example demonstrates different ways of implementing an adder/subtractor.
// IMPORTANT: Use this file as the top-level module to collect resources counts
// and the add_sub_timing.sv as the top-level module to perform timing analysis.
// The timing version will add in registers that affect the resource count.

// Module: add_sub_large
// Description: In this implementation, we simply select between the subtractor
// and adder results using the sel signal. In the RTL viewer of Quartus, the
// circuit is two adders followed by a MUX that is controlled by the sel signal.
// However, when looking at the technology-mapped viewer, the circuit looks
// largely like a normal ripple-carry adder, but with one extra ALM that is
// needed to connect the sel input to the carry in of the ripple-carry adder.
// In addition the sel is being used to invert one of the inputs, but that
// happens within the same LUTs for the add, so there is no overhead.
//
// This is still pretty close to the ideal situation, except for the extra
// ALM that solely handles the carry in. It appears that an ALM input cannot
// connect directly to the carry in, and must instead come from another ALM
// whose carry out is a hardened connection to the carry in of an adjacent ALM.

// For a 32-bit width, this module required 17 ALMs.
// Slow 900mV 100C model (611.62 MHz)

module add_sub_large
  #(parameter int WIDTH)
   (
    input logic [WIDTH-1:0]  in0, in1,
    input logic 	     sel,
    output logic [WIDTH-1:0] out
    );

   logic [WIDTH-1:0] 	     in1_adj;
   
   always_comb begin
      if (sel) out = in0 - in1;
      else out = in0 + in1;     
   end
   
endmodule


// Module: add_sub_small
// Description: In this implementation, we explicitly do the inversion of one
// of the inputs based on the sel signal, while then using the sel as the
// carry in to the resulting add. Conceptually, this is identical to what
// Quartus did for us in the previous module. However, when described this way
// explicitly, Quartus is able to modify the logic so that the carry in is
// always 0. To see why, see the 3-input adder example for a detailed 
// explanation.
//
// NOTE: I don't see any fundamental reason why Quartus couldn't convert the
// previous module into the same circuit as this module. So, the point here
// isn't that this module is better, it is that synthesis tools often handle
// similar code in different ways, which is important to be aware when doing
// optimizations.

// For a 32-bit width, this module required 16 ALMs.
// Slow 900mV 100C model (590.32 MHz)
// NOTE: although this module is slightly slower, I suspect it is partly from
// randomness in place and route resulting from the 1 GHz constraint.
// TODO: Write a TCL script to explore a bunch of different clock constraints.

module add_sub_small
  #(parameter int WIDTH)
   (
    input logic [WIDTH-1:0]  in0, in1,
    input logic 	     sel,
    output logic [WIDTH-1:0] out
    );

   logic [WIDTH-1:0] 	     in1_adj;
   
   always_comb begin

      if (sel) in1_adj = ~in1;
      else in1_adj = in1;      
      out = in0 + in1_adj + sel;            
   end   
endmodule



// Module: add_sub_fa
// Description: Next we attempt explicitly specifying logic for a ripple carry 
// adder that is also capable of subtraction by inverting one input based on
// the select. To do this, we modify a standard full adder to invert the
// y input when the select is asserted.

module add_sub_fa
  (
   input logic 	x, y, cin, sel,
   output logic result, cout     
   );
   
   logic 	y_adj;   
   assign y_adj = y ^ sel; // Invert the y input based on the select.
   assign result = x ^ y_adj ^ cin;
   assign cout = x & y_adj | x & cin | y_adj & cin; 
endmodule
      

// Module: add_sub_rc
// Description: This creates the ripple-carry adder/subtractor out of modified
// full adders.
//
// In this case, each add_sub_fa requires a 4-input, 2-output LUT. The targeted
// FPGA does not have such a LUT, so the synthesized design ends up taking
// more ALMs.
//
// Again, in theory, a synthesis tool could potentially convert this into a
// similar circuit as the previous circuits. However, to do that, it would have
// to recognize the logic equations for a full adder, and map that code on to
// the hardened adder within each ALM. Generally, synthesis will only ever use
// a hardened adder when explicitly using the + operator in your code.
//
// For a 32-bit width, this module required 54 ALMs. - MUCH BIGGER
// Slow 900mV 100C model (304.23 MHz) - MUCH SLOWER

module add_sub_rc
  #(parameter int WIDTH)
   (
    input logic [WIDTH-1:0]  in0, in1,
    input logic 	     sel,
    output logic [WIDTH-1:0] out
    );
   
   logic [WIDTH:0] 	     carry;
   
   genvar 		     i;  
   generate
      assign carry[0] = sel;
      
      for (i=0; i < WIDTH; i++) begin : l_fas
	 add_sub_fa fa (.x(in0[i]), .y(in1[i]), .cin(carry[i]), .sel(sel), .result(out[i]), .cout(carry[i+1]));	 
      end      
   endgenerate		          
endmodule


// Module: add
// Description: A basic adder, which is provided to get resource usage without
// the subtractor.
//
// For a 32-bit width, this module required 16 ALMs.
// Slow 900mV 100C model (654.45 MHz, 645.16 MHz restricted)

module add
  #(parameter int WIDTH)
   (
    input logic [WIDTH-1:0]  in0, in1,
    output logic [WIDTH-1:0] out
    );
   
   always_comb begin
      out = in0 + in1;     
   end
   
endmodule


// Module: add_sub
// Description: Top-level used for synthesizing each implementation.

module add_sub
  #(parameter int WIDTH=32)
   (
    input logic [WIDTH-1:0]  in0, in1,
    input logic 	     sel,
    output logic [WIDTH-1:0] out
    );

   // Only provided for convenience to get the adder resource count.
   add #(.WIDTH(WIDTH)) top (.*);
   
   //add_sub_large #(.WIDTH(WIDTH)) top (.*);
   //add_sub_small #(.WIDTH(WIDTH)) top (.*);
   //add_sub_rc #(.WIDTH(WIDTH)) top (.*);

      
endmodule
