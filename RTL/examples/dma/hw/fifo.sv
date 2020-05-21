// Copyright (c) 2020 University of Florida
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Greg Stitt
// University of Florida

// Module Name:  fifo.sv
// Description:  This module implements a basic FIFO with parameters for
//               width (number of bits), depth (number of elements in FIFOs),
//               and a configurable almost full flag. The FIFO provides
//               the output on the same cycle that empty is cleared, as opposed
//               to some FIFOs that have a 1+ cycle latency when asserting
//               rd_en.
//
// Notes: FIFOs that provide data on the same cycle that empty is cleared, as
//        opposed to 1+ cycles after rd_en is asserted tend to have lower max
//        clock frequencies. This particular FIFO style was chosen to simplify
//        the control logic in the rest of the application.

//==========================================================================
// Parameter Description
// width             : the width of the FIFO in bits 
// depth             : the depth of the FIFO in words
// almost_full_count : the count at which almost_full is asserted.
//==========================================================================

//==========================================================================
// Interface Description (all control inputs are active high)
// clk         : clock
// rst         : reset (asynchronous)
// rd          : read enable, acts like a read acknowledgement since data
//               is already available on rd_data when !empty.
// wr          : write enable
// empty       : asserted when the FIFO is empty
// full        : asserted when the FIFO is full
// almost_full : asserted when count >= ALMOST_FULL_COUNT parameter
// count       : specifies the current number of words in the FIFO
// space       : specifies the current remaining space in the FIFO before
//               being completely full
// wr_data     : input to write into the FIFO
// rd_data     : output read from the FIFO, available in the same cycle that
//               empty is cleared.
//==========================================================================

module fifo #(parameter int WIDTH,
	      parameter int DEPTH,
	      parameter int ALMOST_FULL_COUNT=DEPTH)
   (
    input logic 		   clk,
    input logic 		   rst,
    input logic 		   rd_en,
    input logic 		   wr_en,
    output logic 		   empty,
    output logic 		   full,
    output logic 		   almost_full,
    output logic [$clog2(DEPTH):0] count,
    output logic [$clog2(DEPTH):0] space,
    input [WIDTH-1:0] 		   wr_data,
    output logic [WIDTH-1:0] 	   rd_data
    );

   localparam ADDR_WIDTH = $clog2(DEPTH);
   
   logic [WIDTH-1:0] 		   mem [2**ADDR_WIDTH];
   logic [ADDR_WIDTH-1:0] 	   wr_addr, rd_addr, rd_addr_adjusted;
   logic [$clog2(DEPTH):0] 	   count_r, next_count;
   logic [$clog2(DEPTH):0] 	   space_r, next_space;
   logic 			   next_full, next_almost_full, next_empty;
   logic 			   valid_rd, valid_wr;
      
   // Create a block RAM for the FIFO.
   // NOTE: This provides the new data when a write occurs to the
   // read address. This is not the recommended way of using a block
   // RAM because it can result in a slower clock.
   always @ (posedge clk) begin
      if (valid_wr) begin
         mem[wr_addr] = wr_data;
      end
      
      rd_data = mem[rd_addr_adjusted];      
   end

   // Adjust the read address to prefetch the next data from the BRAM
   // on a valid read. This is necessary to have the data appear on the
   // read port before receiving the rd_en.
   assign rd_addr_adjusted = (valid_rd == 1'b0) ? rd_addr : rd_addr+1'b1;

   // Safety checks to prevent reads when empty and writes when full.
   assign valid_wr = wr_en && !full;
   assign valid_rd = rd_en && !empty;
   
   always_ff @ (posedge clk or posedge rst) begin     
      if (rst) begin
	 wr_addr     <= '0;
	 rd_addr     <= '0;
	 count_r     <= '0;
	 space_r     <= (ADDR_WIDTH+1)'(DEPTH);	   
	 full 	     <= '1;
	 almost_full <= '1;	   
	 empty 	     <= '1;	   
      end
      else begin
	 if (valid_rd)
	   rd_addr <= rd_addr + 1'b1;
	      	 
	 if (valid_wr)
	   wr_addr <= wr_addr + 1'b1;
	 	 	 
	 count_r     <= next_count;	   
	 space_r     <= next_space;	   
	 full 	     <= next_full;
	 almost_full <= next_almost_full;
	 empty 	     <= next_empty;	   
      end
   end // always_ff @
   
   always_comb begin

      next_full 	= 1'b0;
      next_empty 	= 1'b0;
      next_almost_full 	= 1'b0;
      next_count 	= count_r;
      next_space 	= space_r;

      // Update the count and space on valid reads/writes.
      if (valid_rd && !valid_wr) begin
	 next_count--;
	 next_space++;       
      end
      else if (!valid_rd && valid_wr) begin
	 next_count++;
	 next_space--;	 
      end;
      
      if (next_count >= ALMOST_FULL_COUNT)
	next_almost_full = 1'b1;
      
      if (next_count == DEPTH)
	next_full = 1'b1;
      
      if (next_count == 0)
	next_empty = 1'b1;         
    
   end // always_comb

   assign count = count_r;
   assign space = space_r;
      
endmodule     
