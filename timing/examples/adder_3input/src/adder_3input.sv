// Greg Stitt
// University of Florida
//
// In this example, we demonstrate how the Intel 10-series FPGAs can implement
// 3-input adders in the same number of ALMs as a 2-input adder.
//
// See adder_3input.pptx for an explanation.
//
// To collect ALM counts, synthesize adder_3input as the top-level module. For
// timing analysis, change the top level to adder_3input_timing so that the
// I/O is registered. Do not use the timing module to collect resources
// because the registered I/O will distort the results.

// Module: adder_3input
// Description: A 3-input adder.

module adder_3input
  #(parameter int WIDTH=16)
   (
    input logic [WIDTH-1:0]  in0, in1, in2,
    output logic [WIDTH-1:0] out
    );

   // Uncomment to test a normal 2-input adder for resources and/or timing.
   // For WIDTH==16:
   // 8 ALMs:
   // Slow 900mV 100C model: (850.34 MHz, 645.26 MHz restricted)
   //assign out = in0 + in1;  
   
   // For WIDTH==16:
   // 8 ALMs:
   // Slow 900mV 100C model: (757.0 MHz, 645.26 MHz restricted)
   // The potential frequency of the 3-input adder is lower due to a longer
   // path through each ALM, but since both adders are above the restricted
   // frequency, they are effectively the same.
   assign out = in0 + in1 + in2;

   // NOTE: The 3-input add starts requiring more ALMs for WIDTH > 16. I suspect
   // this is because the shared_out and carry_out signals can't propagate
   // indefinitely between adjacent ALMs. I need to verify, but I'm guessing
   // once reaching the end of a LAB, extra ALMs are need to handle the
   // transition between the next lab.
         
endmodule
