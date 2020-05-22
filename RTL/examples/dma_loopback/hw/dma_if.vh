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

// Description:  This header provides an abstract DMA interface that hides the
//               details of CCI-P.
//
//               The DMA read interface takes a starting read address (rd_addr),
//               and a read size (rd_size) (# of cache lines to read). The rd_go
//               signal starts the transfer. When data is available from memory
//               the empty signal is cleared (0 == data available) and the data
//               is shown on the rd_data port. To read the data, the AFU should
//               assert the read enable (rd_en) (active high) for one cycle.
//               The rd_done signal is continuously asserted (active high) after
//               the AFU reads "size" words from the DMA.
//
//               The DMA write interface is similar, again using a starting
//               write address (wr_addr), write size (wr_size), and go signal.
//               Before writing data, the AFU must ensure that the write
//               interface is not full (full == 0). To write data, the AFU
//               puts the corresponding data on wr_data and asserts wr_en
//               (active high) for one cycle. The wr_done signal is continuosly
//               asserted after size cache lines have been written to memory.

`ifndef DMA_IF
`define DMA_IF

interface dma_if #(parameter int DATA_WIDTH, 
		   parameter int ADDR_WIDTH,
		   parameter int SIZE_WIDTH);

   typedef logic [ADDR_WIDTH-1:0] addr_t;
   typedef logic [SIZE_WIDTH-1:0] count_t;

   logic rd_go, rd_done, rd_en, empty;
   logic [DATA_WIDTH-1:0] rd_data;
   addr_t rd_addr;
   count_t rd_size;

   logic   wr_go, wr_done, wr_en, full;
   logic [DATA_WIDTH-1:0] wr_data;
   addr_t wr_addr;
   count_t wr_size;

   function int getAddrWidth;
      return ADDR_WIDTH;
   endfunction
   
   modport mem 
     (
      import getAddrWidth,
      
      input  rd_go,
      input  rd_en,
      input  rd_addr,
      input  rd_size,
      output rd_data,
      output rd_done,
      output empty,

      input  wr_go,
      input  wr_en,
      input  wr_addr,
      input  wr_size,
      input  wr_data,
      output wr_done,
      output full				
      );
   
   modport peripheral 
     (
      import getAddrWidth,
      
      output rd_go,
      output rd_en,
      output rd_addr,
      output rd_size,
      input  rd_data,
      input  rd_done,
      input  empty,
		       
      output wr_go,
      output wr_en,
      output wr_addr,
      output wr_size,
      output wr_data,
      input  wr_done,
      input  full		       
      );
   
endinterface

`endif
