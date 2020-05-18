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

// Module Name:  afu.sv
// Project:      dma_loopback
// Description:  This AFU provides a loopback DMA test that simply reads
//               data from one array in the CPU's memory and writes the
//               received data to a separate array. The AFU uses MMIO to
//               receive the starting read adress, starting write address,
//               size (# of cache lines to read/wite), and a go signal. The
//               AFU asserts a done signal to tell software that the DMA
//               transfer is complete.
//
//               One key difference with this AFU is that it does not use
//               CCI-P, which is abstracted away by a hardware abstraction
//               layer (HAL). Instead, the AFU uses a simplified MMIO interface
//               and DMA interface.
//
//               The MMIO interface is defined in mmio_if.vh. It behaves
//               similarly to the CCI-P functionality, except only supports
//               single-cycle MMIO read responses, which eliminates the need
//               for transaction IDs. MMIO writes behave identically to
//               CCI-P.
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
//
//               All addresses are virtual addresses provided by the software.
//               All data elements are cachelines.
//

//===================================================================
// Interface Description
// clk  : Clock input
// rst  : Reset input (active high)
// mmio : Memory-mapped I/O interface. See mmio_if.vh and description above.
// dma  : DMA interface. See dma_if.vh and description above.
//===================================================================

`include "cci_mpf_if.vh"

module afu 
  (
   input clk,
   input rst,
	 mmio_if.user mmio,
	 dma_if.peripheral dma
   );

   // The DMA uses physical cache line addresses.
   // Strangely, when just doing dma.ADDR_WIDTH I get errors saying "constant 
   // expression cannot contain a hierarchical identifier" in some tools. 
   // Declaring a getAddrWidth function within the interface works just fine in
   // some tools, but in Quartus I get an error about too many ports in the
   // module instantiation. The third option works in every tool but is my
   // least preferred because it relies on structures that are external to the
   // module and specific to the platform.
   //localparam int DMA_ADDR_WIDTH = dma.ADDR_WIDTH;   
   //localparam int DMA_ADDR_WIDTH = dma.getAddrWidth();   
   localparam int DMA_ADDR_WIDTH = $size(t_ccip_clAddr);
      
   // I want to just use dma.count_t, but apparently
   // either SV or Modelsim doesn't support that. Similarly, I can't
   // just do dma:ADDR_WIDTH without getting errors or warnings about
   // "constant expression cannot contain a hierarchical identifier" in
   // some tools. 
   typedef logic [DMA_ADDR_WIDTH:0] count_t;   
   count_t 	size;
   logic 	go;
   logic 	done;

   // Software provides 64-bit virtual byte addresses.
   localparam int SOFTWARE_ADDR_WIDTH = 64;
   logic [SOFTWARE_ADDR_WIDTH-1:0] rd_addr, wr_addr;

   // Instantiate the memory map, which provides the starting read/write
   // 64-bit virutal byte addresses, a transfer size (in cache lines), and a
   // go signal. It also sends a done signal back to software.
   memory_map
     #(
       .ADDR_WIDTH(64),
       .SIZE_WIDTH(DMA_ADDR_WIDTH+1)
       )
     memory_map (.*);

   // Each CL has 64 bytes, so the byte index is log2(64) = 6 bits.
   localparam CL_BYTE_INDEX_BITS = 6;
   
   // Converts the 64-bit virtual byte addresses to CL addresses.
   // This just removes 6 low-end bits since there are 64 bytes in a cache line.
   assign dma.rd_addr = rd_addr[CL_BYTE_INDEX_BITS +: $size(t_cci_clAddr)];
   assign dma.wr_addr = wr_addr[CL_BYTE_INDEX_BITS +: $size(t_cci_clAddr)];

   // Use the size (# of cache lines) specified by software.
   assign dma.rd_size = size;
   assign dma.wr_size = size;

   // Start both the read and write channels when the MMIO go is received.
   // Note that writes don't actually occur until dma.wr_en is asserted.
   assign dma.rd_go = go;
   assign dma.wr_go = go;

   // Read from the DMA when there is data available (!dma.empty) and when
   // it is safe to write data (!dma.full).
   assign dma.rd_en = !dma.empty && !dma.full;

   // Since this is a simple loopback, write to the DMA anytime we read.
   assign dma.wr_en = dma.rd_en;

   // Write the data that is read.
   assign dma.wr_data = dma.rd_data;

   // The AFU is done when the DMA is done writing size cache lines.
   assign done = dma.wr_done;
            
endmodule




