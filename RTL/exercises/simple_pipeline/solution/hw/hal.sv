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

// Module Name:  hal.sv
// Description:  Implements a hardware abstraction layer (HAL) that hides
//               the details of CCI-P and replaces them with a simpler
//               MMIO and DMA interface and protocol. Although removing some
//               of the flexibility of CCI-P, this more abstract interface
//               makes the code easier to use for use cases that don't require
//               the full CCI-P functionality.

//===================================================================
// Parameter Description
// MMIO_START_ADDR : The 32-bit word starting address of the MMIO addresses
//                   used by the AFU within the HAL.
// MMIO_END_ADDR : The 32-bit word ending address of the MMIO addresses
//                   used by the AFU within the HAL.
//===================================================================

//===================================================================
// Interface Description
// clk  : Clock input
// rst  : Reset input (active high)
// cci  : Cache cache interface signals
// c0Empty : Asserted (active high) when there are no pending reads
// c1Empty : Asserted (active high) when there are no pending writes
//===================================================================

`include "cci_mpf_platform.vh"
`include "csr_mgr.vh"

module hal
  #(
    parameter int MMIO_START_ADDR,
    parameter int MMIO_END_ADDR
    )   
   (
    input logic clk,
    input logic rst,
		
    cci_mpf_if.to_fiu cci,
    
    input logic c0Empty,
    input logic c1Empty   
    );

   localparam int MMIO_DATA_WIDTH         = 64;
   localparam int MMIO_ADDR_WIDTH         = 16;
   localparam int VIRTUAL_BYTE_ADDR_WIDTH = 64;
   
   // Instantiate the DMA interface signals.
   dma_if 
     #(
       .DATA_WIDTH($size(t_ccip_clData)),
       .ADDR_WIDTH(VIRTUAL_BYTE_ADDR_WIDTH),
       .SIZE_WIDTH($size(t_ccip_clAddr)+1)
       ) dma();

   // Instantiate the MMIO interface signals.
   // TODO: Replace hardcoded values with $size of CCI signals.
   mmio_if 
     #(
       .DATA_WIDTH(MMIO_DATA_WIDTH),
       .ADDR_WIDTH(MMIO_ADDR_WIDTH),
       .START_ADDR(MMIO_START_ADDR),
       .END_ADDR(MMIO_END_ADDR)
       ) mmio();

   // Convert the DMA interface into CCI-P
   cci_dma dma_ctrl
     (
      .clk(clk),
      .rst(rst),

      // This module originally just passed CCI, but Quartus was reporting
      // errors about multiple drivers because the hal module was modifying
      // the c2Tx signals. Although technical no signal within CCI had multiple
      // drivers, Quartus apparently treats the entire interface a single
      // signal, so any two modules that assign values to the same interface
      // are seen as multiple drivers. I'm not sure if this behavior is
      // defined by the SV standard, or if tool specific. 
      //.cci(cci),   
      .c0Tx(cci.c0Tx),
      .c0TxAlmFull(cci.c0TxAlmFull),
      .c1Tx(cci.c1Tx),
      .c1TxAlmFull(cci.c1TxAlmFull),
      .c0Rx(cci.c0Rx),
      
      .dma(dma),
      .c0Empty,
      .c1Empty
      );
         
   //===================================================================
   // Convert CCI-P MMIO to the simplified HAL MMIO protocol.   
   assign mmio.rd_en = cci_csr_isRead(cci.c0Rx);
   assign mmio.wr_en = cci_csr_isWrite(cci.c0Rx);
   assign mmio.rd_addr = cci_csr_getAddress(cci.c0Rx);
   assign mmio.wr_data = 64'(cci.c0Rx.data);
   assign mmio.wr_addr = cci_csr_getAddress(cci.c0Rx);
   assign cci.c2Tx.data = mmio.rd_data;
   
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 cci.c2Tx.mmioRdValid <= '0;
      end
      else begin

	 cci.c2Tx.mmioRdValid <= '0;

	 // Don't respond to addresses outside the MMIO range of the AFU
	 // otherwise there will be conflicts with other resources.
	 if (cci_csr_getAddress(cci.c0Rx) >= mmio.START_ADDR &&
	     cci_csr_getAddress(cci.c0Rx) <= mmio.END_ADDR) begin
	    cci.c2Tx.mmioRdValid <= mmio.rd_en;
	 end
	 
	 cci.c2Tx.hdr.tid <= cci_csr_getTid(cci.c0Rx);	 
      end
   end 
   //===================================================================

   // Instantiate the AFU with the simplified HAL protocol
   // In this case, the AFU has a DMA interface for accessing CPU RAM,
   // in addition to an MMIO interface for normal MMIO communication.
   afu afu
     (
      .clk(clk),
      .rst(rst),
      .mmio(mmio),
      .dma(dma.peripheral)
      );

endmodule
