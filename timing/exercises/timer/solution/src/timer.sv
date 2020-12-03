// Greg Stitt
// University of Florida

// Module Name:  timer.sv
// Description:  This module provides a timer that counts "cycles" cycles after
// receiving a "go" input, and asserts a "done" signal upon completion. The
// done signal remains asserted indefinitely until go is asserted again.
//
// NOTE: Cycles must be positive.

//===================================================================
// Parameter Description
// WIDTH : The data width (number of bits) of the cycles input.
//===================================================================

//===================================================================
// Interface Description
// clk  : Clock input
// rst  : Reset input (active high)
// go   : Assert to start the timer (active high)
// cycles : The number of cycles to count, must be > 0.
// done   : Asserted after "cycles" cycles have elapsed. Remains asserted
//          until go is asserted again.
//===================================================================

module timer #(parameter int WIDTH=32)		   		  
  (
   input  		    clk,
   input  		    rst,
   input  		    go, 
   input [WIDTH-1:0] 	    cycles,
   output logic             done
   );

   enum 		    {IDLE, WORKING} state_r, next_state; 
   logic [WIDTH-1:0] 	    count_r, next_count;
   logic [WIDTH-1:0] 	    cycles_r, next_cycles;

   always_ff @(posedge clk or posedge rst) begin

      if (rst) begin
	 state_r  <= IDLE;
	 count_r  <= '0;
	 cycles_r <= '0;
	 	 	 	 
      end else begin

	 // Create all the registers.
	 state_r  <= next_state;
	 count_r  <= next_count;	 
	 cycles_r <= next_cycles;	 
      end 
   end

   always_comb begin

      // By default, simply set the next values to the current values.
      next_state  = state_r;
      next_count  = count_r;
      next_cycles = cycles_r;
      
      unique case (state_r)

	// Wait until go is asserted
	IDLE : begin
	  done = 1'b1;
	
	  if (go == 1'b1) begin
	     next_state  = WORKING;

	     // Starting counting down from cycles to 1.
	     next_count  = cycles;

	     // Save the cycles into an internal register.
	     next_cycles = cycles;	     
	  end
	end

	// Count down from cycles to 1. By counting down to a constant, the 
	// comparator now has half as many inputs as in the original code,
	// which improves the maximum clock frequency.
	WORKING : begin
	   done = 1'b0;
	   
	   if (count_r == 1) begin
	      done       = 1'b1;	     
	      next_state = IDLE;
	   end else begin
	      next_count = count_r - 1'd1;	     
	   end
	end	
	
      endcase
   end

endmodule
