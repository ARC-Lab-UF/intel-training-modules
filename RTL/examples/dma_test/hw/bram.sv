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

// Module Name:  bram.sv
// Description:  Implements a block RAM with a registered output (2-cycle read latency).
//               The RAM provides old read data during a read&write to the samea address.
//
// For more information on block RAM inference from HDL code, see Intel documentation.
// There are different styles of inference for different types of RAM resources, and
// for different read-during-write behaviors.

//===================================================================
// Parameter Description
// DATA_WIDTH : The number of bits in each RAM word.
// ADDR_WIDTH : The number of bits in each RAM address. Also determines
//              the number of words in the RAM (2**ADDR_WIDTH).
//===================================================================

//===================================================================
// Interface Description
// clk  : Clock input
// wr_en : Write enable (active high)
// wr_addr : Write addr
// wr_data : Write data
// rd_addr : Read addr
// rd_data : Read data
//===================================================================

module bram
  #(
    parameter int DATA_WIDTH,
    parameter int ADDR_WIDTH
    )
   (
    input 			  clk,

    // Write port
    input 			  wr_en,
    input [ADDR_WIDTH-1:0] 	  wr_addr,
    input [DATA_WIDTH-1:0] 	  wr_data,

    // Read port
    input [ADDR_WIDTH-1:0] 	  rd_addr,
    output logic [DATA_WIDTH-1:0] rd_data
    );
   
   logic [DATA_WIDTH-1:0] 	  mem [2**ADDR_WIDTH];
   logic [DATA_WIDTH-1:0] 	  mem_data;
   
   always @ (posedge clk) begin
      if (wr_en) begin
         mem[wr_addr] = wr_data;
      end

      // This statement ensures the RAM uses the old data during a read/write conflict.
      // Mem_data is the output of the block RAM by itself.
      mem_data <= mem[rd_addr];

      // Register the memory output. This isn't necessary for a block RAM but 
      // can often eliminating timing-closure bottlenecks.
      rd_data <= mem_data; 
   end // always @ (posedge clk)
   
endmodule
