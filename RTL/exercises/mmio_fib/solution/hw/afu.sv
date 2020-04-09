// Greg Stitt
// University of Florida
//
// Module Name:  afu.sv
// Project:      mmio_fib
// Description:  Implements an AFU that calcuates Fibonacci numbers
//               using MMIO over CCI-P. Software provides an input n,
//               which corresponds to the nth Fibonacci number,
//               along with a go signal to start the computation.
//               The module outputs the result and asserts a done signal,
//               which can be read by software over MMIO.

`include "platform_if.vh"

module afu
  (
   input  clk,
   input  rst, 
  
   // CCI-P signals
   input  t_if_ccip_Rx rx,
   output t_if_ccip_Tx tx
   );

   // Connectinos between the memory map and fib module
   logic  go, done;
   logic [31:0] n, result;

   // In this example, we separate the memory mapping from the main
   // functionality of the AFU because they are more complex.
   // The memory map provides the input n and go signals from software, 
   // and transfers the result and done signals back to software.
   memory_map memory_map (.*);

   // The main Fibonacci calculator. This module takes the input n
   // from a memory-mapped register, and computes the nth Fibonacci
   // number when go is asserted. It outputs the result on the result
   // output, and asserts done in the cycle that result is valid.
   fib fib (.*);  
   
endmodule
