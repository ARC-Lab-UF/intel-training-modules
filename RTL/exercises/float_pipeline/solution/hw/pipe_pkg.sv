`ifndef __PIPE_PKG__
`define __PIPE_PKG__

package pipe_pkg;

   localparam int MULT_LATENCY = 3;
   localparam int ADD_LATENCY  = 3;

   // Normally I would make this a function of the number of inputs, but since
   // the pipeline is hardcoded for a specific number of inputs in this example,
   // this will suffice.
   // The *3 is because of the 3 levels of adders. The +1 is for the 
   // registered inputs.    
   localparam int PIPE_LATENCY = MULT_LATENCY + ADD_LATENCY*3 + 1;

endpackage

`endif
