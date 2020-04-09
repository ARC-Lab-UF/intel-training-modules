// Module Name:  fib.sv
// Project:      mmio_fib
// Description:  Implements a simple Fibonacci calculator for the following
//               algorithm:
//
// x = 0;
// y = 1;
//
// if (n == 0)
//   return 0;
//
// for (i=2; i <= n; i++) {    
//   temp = x+y;
//   x = y;
//   y = temp;
// }
//   
// return y;


//========================================================================
// Port Description
// clk : clock
// rst : reset
// go : Assert to start the circuit. To restart the circuit, go must be
//      cleared before being asserted again.
// n : Specifies the nth Fibonacci number to calculate
// done : Asserted when result output is valid. Remains asserted until
//        circuit is restarted.
// result : The nth Fibonacci number, valid when done is asserted
//========================================================================

module fib
  (
   input 	 clk,
   input 	 rst, 
   input 	 go,
   input [31:0]  n,
   output logic	 done,
   output logic [31:0] result
   );

   // TODO: Implement a Fibonacci calculator for the pseudo-code provided
   // above.
  
   
endmodule
