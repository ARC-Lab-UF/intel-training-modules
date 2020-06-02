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

// Module Name:  cci_dma
// Description:  This module converts the DMA interface in dma_if.vh into
//               CCI-P.

`include "cci_mpf_if.vh"

module cci_dma
   (
    input 	clk,
    input 	rst,
   
    // CCI signals for mem reads/writes
    // NOTE: This was originally just a cci_mpf_if interface, but Quartus
    // was reporting multiple driver errors even though not signals within
    // the interface had more than one driver. Not sure if this is a SV
    // defined behavior, or a Quartus issue. In any case, this code separates
    // all the signals from cci_mpf_if that are needed by this module.
    output 	t_if_cci_mpf_c0_Tx c0Tx,
    input logic c0TxAlmFull,
    output 	t_if_cci_mpf_c1_Tx c1Tx,
    input logic c1TxAlmFull,
    input 	t_if_cci_c0_Rx c0Rx,
		
		dma_if.mem dma,
    input logic c0Empty,
    input logic c1Empty
   );

   localparam int FIFO_DEPTH = 512;   
   localparam int CL_ADDR_WIDTH = $size(t_ccip_clAddr);
      
   // The counts are intentionally one bit larger to support counts from 0
   // to the maximum possible number of cachelines. For example, 8 cachelines
   // requires 4 bits (4'b1000). However, there are 8 different addresses,
   // which only requires 3 bits (3'b000 to 3'b111).
   logic [CL_ADDR_WIDTH:0] cci_rd_remaining_r;
   logic [CL_ADDR_WIDTH:0] cci_rd_pending_r;
   logic [CL_ADDR_WIDTH:0] dma_rd_remaining_r;   
   logic [CL_ADDR_WIDTH:0] cci_wr_remaining_r;   
   logic [CL_ADDR_WIDTH-1:0] rd_addr_r, wr_addr_r;
   
   // Create the read header that defines the request to the FIU
   t_cci_mpf_c0_ReqMemHdr rd_hdr;
   t_cci_mpf_ReqMemHdrParams rd_hdr_params;
   
   always_comb begin
      // Tell MPF to use virtual addresses.
      rd_hdr_params = cci_mpf_defaultReqHdrParams(1);
      
      // Tell the FIU to automatically select the communciation channel.
      rd_hdr_params.vc_sel = eVC_VA;
      
      // Always read 1 cacheline. This can be optimized
      // but is kept simple for this training example.
      rd_hdr_params.cl_len = eCL_LEN_1;
      
      // Create the memory read request header.
      rd_hdr = cci_mpf_c0_genReqHdr(eREQ_RDLINE_I,
                                    rd_addr_r,
                                    t_cci_mdata'(0),
                                    rd_hdr_params);
   end // always_comb
   
   logic rd_fifo_almost_full;
   
   // A read request should happen when there are still
   // cachelines to be read and the read request buffer isn't
   // almost full, and the read data buffer isn't almost full.
   logic cci_rd_en;   
   assign cci_rd_en = cci_rd_remaining_r > 0 && 
		      !c0TxAlmFull &&
		      !rd_fifo_almost_full;

   // Make read requests (on the CCI c0 Tx port).
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 // Only the valid bit needs to be cleared on reset.
         c0Tx.valid <= 1'b0;
      end      
      else begin
	 // Assign the read request signals, which is enabled by cci_rd_en.
         c0Tx <= cci_mpf_genC0TxReadReq(rd_hdr, cci_rd_en);	 
      end
   end

   // Determine when CCI is providing read data.
   logic rd_response_valid;
   assign rd_response_valid = cci_c0Rx_isReadRsp(c0Rx);
   
   logic [$clog2(FIFO_DEPTH):0] rd_fifo_space;

   // The read FIFO is almost full when the number of pending CCI reads
   // is equal to the space left in the FIFO.
   assign rd_fifo_almost_full = cci_rd_pending_r >= rd_fifo_space ? 1'b1 : 1'b0;
   
   // FIFO to buffer memory reads before the AFU reads it from the DMA channel.
   fifo 
     #(
       .WIDTH($size(c0Rx.data)),
       .DEPTH(FIFO_DEPTH)
       )
   rd_fifo 
     (
      .clk(clk),
      .rst(rst),
      .empty(dma.empty),
      .rd_data(dma.rd_data),
      .rd_en(dma.rd_en),
      
      .full(),
      .almost_full(),
      .count(),
      .space(rd_fifo_space), 
      .wr_data(c0Rx.data),
      .wr_en(rd_response_valid),
      .*
      );     					       
   
   // Construct a memory write request header.  
   t_cci_mpf_c1_ReqMemHdr wr_hdr;
   assign wr_hdr = cci_mpf_c1_genReqHdr(eREQ_WRLINE_I,
                                        wr_addr_r,
                                        t_cci_mdata'(0),
                                        cci_mpf_defaultReqHdrParams(1));

   // Make a CCI write request when the dma receives a wr_en, and when the
   // CCI write Tx channel isn't almost full, and when there are still
   // things left to write.
   logic cci_wr_en;
   assign cci_wr_en = dma.wr_en && !c1TxAlmFull && cci_wr_remaining_r > 0;
   
   // Control logic for memory writes
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
         c1Tx.valid <= 1'b0;
      end
      else begin
         c1Tx.valid <= cci_wr_en;	 
	 c1Tx.hdr   <= wr_hdr;
	 c1Tx.data  <= dma.wr_data;
      end
   end
   
   logic cci_wr_en_delayed;
   
   // Reads are done when the last element is read out of the dma.
   // There shouldn't be a need to check for anything else, unless more
   // cachelines were fetched than were needed, which shouldn't ever occur.
   logic reads_are_pending;
   assign reads_are_pending = dma_rd_remaining_r > 0;   
   
   // There is a 2-cycle delay between a write request and c1Empty being
   // cleared, so we need to account for that delay otherwise the DMA
   // could signal that it is done before the last write is in memory.
   logic writes_are_pending;
   assign writes_are_pending = cci_wr_en_delayed || !c1Empty || 
			       cci_wr_remaining_r > 0;   

   // Each cache line has 64 bytes, so the byte index is log2(64) = 6 bits.
   localparam CL_BYTE_INDEX_BITS = 6;
   
   always_ff @ (posedge clk or posedge rst) begin
      if (rst == 1'b1) begin
	 cci_rd_remaining_r 	<= '0;
	 dma_rd_remaining_r 	<= '0;
	 cci_rd_pending_r 	<= '0;	 
	 cci_wr_remaining_r 	<= '0;
	 cci_wr_en_delayed 	<= '0;
      end
      else begin

	 // Initialize read registers on go. The && rd_done ensures that
	 // a user modifying go during execution doesn't corrupt the state.
	 if (dma.rd_go && dma.rd_done) begin
	    // Converts the virtual byte addresses to a cache line address.
	    // This just removes 6 low-end bits from the 64-bit virtual addr.
	    rd_addr_r <= dma.rd_addr[CL_BYTE_INDEX_BITS +: $size(t_cci_clAddr)];
	    cci_rd_remaining_r <= dma.rd_size;
	    dma_rd_remaining_r <= dma.rd_size;
	 end 

	 // Initialize write registers on go. The && wr_done ensures that
	 // a user modifying go during execution doesn't corrupt the state.
	 if (dma.wr_go && dma.wr_done) begin
	    // Converts the virtual byte addresses to a cache line address.
	    // This just removes 6 low-end bits from the 64-bit virtual addr.
	    wr_addr_r <= dma.wr_addr[CL_BYTE_INDEX_BITS +: $size(t_cci_clAddr)];
	    cci_wr_remaining_r <= dma.wr_size;
	 end
	
	 // Decrement the number of remaining reads on a valid read.
	 if (dma.rd_en && !dma.empty) begin
	    dma_rd_remaining_r <= dma_rd_remaining_r - 1;	    
	 end

	 // On a CCI read request, update the read registers.
	 if (cci_rd_en) begin
	    rd_addr_r 	       <= rd_addr_r + 1;	    
	    cci_rd_remaining_r <= cci_rd_remaining_r - 1;
	    
	    // Purposesly blocking since this will be upated again below.
	    cci_rd_pending_r 	= cci_rd_pending_r + 1;	    
	 end

	 // When CCI reponds with data, decrement the pending reads.
	 if (rd_response_valid) begin
	    cci_rd_pending_r = cci_rd_pending_r - 1;	    
	 end
	 
	 // Update the write address on a valid DMA write.
	 if (dma.wr_en && !dma.full) begin
	    wr_addr_r <= wr_addr_r + 1;	    
	 end
	 
	 // On a CCI write request, decrement the remaining requests
	 if (cci_wr_en) begin
	    cci_wr_remaining_r <= cci_wr_remaining_r - 1;	    
	 end
	 
	 // Delay with an extra flip flop.
	 cci_wr_en_delayed <= cci_wr_en;
      end      
   end 

   // Assign DMA interface outputs.
   assign dma.rd_done = !reads_are_pending;
   assign dma.wr_done = !writes_are_pending;
   assign dma.full    = c1TxAlmFull;
  
endmodule

