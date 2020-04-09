// Module Name:  memory_map.sv
// Project:      mmio_fib
// Description:  Implements the memory mapping for the fib I/O
//               Software provides two inputs (n and go), where
//               n specifies which Fibonacci number to calculate
//               and go tells the AFU to start.
//
//               The AFU produces two outputs (result and done),
//               where result is the corresponding Fibonacci number
//               and the assertion of done signifies the completion.
//
//               Input n and output result should be 32 bits.
//
//               n      : h0020
//               go     : h0022
//               result : h0024
//               done   : h0026


`include "platform_if.vh"
`include "afu_json_info.vh"

module memory_map
  (
   input  clk,
   input  rst, 

   // CCI-P signals
   input  t_if_ccip_Rx rx,
   output t_if_ccip_Tx tx,

   // Memory-mapped signals that communicate with fib module
   output [31:0] n,
   output go,
   input [31:0] result,
   input done
   );

   // TODO: Create the MMIO required for basic AFU functionality, and for the
   // memory-mapped connections needed for the fib module.
   

endmodule

   
