// Greg Stitt
// University of Florida
//
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

   typedef enum  {START, INIT, LOOP_COND, LOOP_BODY, COMPLETE} state_t;
   state_t state;

   logic [31:0]  n_r, i, x, y;

   // Simple FSMD for the targeted algorithm.   
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 state 	<= START;
	 result <= '0;
	 done 	<= '0;
	 n_r 	<= '0;	 
	 i 	<= '0;
	 x 	<= '0;
	 y 	<= '0;	 
      end 
      else begin
	 case (state)
	   START: begin
	      if (go) begin
		 state <= INIT;

		 // This clears done the cycle after the circuit is
		 // started. To clear done within the same cycle, done
		 // should be changed to combinational logic.
		 done  <= 1'b0;		 
	      end
	   end
	   
	   INIT: begin
	      i   <= 2;
	      x   <= 0;
	      y   <= 1;
	      // Store input n into a register to prevent
	      // modification during execution. 	    
	      n_r <= n;

	      if (n == 0) begin
		 y     <= 0;
		 state <= COMPLETE;
	      end
	      else begin     		 
		 state <= LOOP_COND;
	      end
	   end

	   LOOP_COND: begin
	      if (i <= n_r) begin
		 state <= LOOP_BODY;
	      end
	      else begin
		 state <= COMPLETE;		 
	      end
	   end

	   LOOP_BODY: begin
	      // Note that non-blocking assignment eliminates the need
	      // for the "temp" variable in the pseudo-code
	      x <= y;
	      y <= x+y;
	      i <= i + 1;
	      state <= LOOP_COND;	      
	   end

	   COMPLETE: begin
	      result <= y;
	      done   <= 1'b1;
	      if (!go) begin
		 state <= START;		 
	      end	     
	   end
	 endcase
      end 
   end    
   
endmodule
