// Greg Stitt
// University of Florida

`include "cci_mpf_if.vh"

module cci_dma 
  (
   input       clk,
   input       rst,
	       cci_mpf_if.to_fiu cci,
	       dma_if.mem dma,
   input logic c0Empty,
   input logic c1Empty
   );

   localparam int FIFO_DEPTH = 512;

   // Strangely, when just doing dma.ADDR_WIDTH I get errors saying "constant 
   // expression cannot contain a hierarchical identifier" in some tools. 
   // However, declaring a function within the interface works just fine.
   //localparam int ADDR_WIDTH = dma.getAddrWidth();
   localparam int ADDR_WIDTH = dma.ADDR_WIDTH;
      
   // The counts are intentionally one bit larger to support counts from 0
   // to the maximum possible number of cachelines. For example, 8 cachelines
   // requires 4 bits (4'b1000). However, there are 8 different addresses,
   // which only requires 3 bits (3'b000 to 3'b111).
   logic [ADDR_WIDTH:0] cci_rd_remaining_r;
   logic [ADDR_WIDTH:0] cci_rd_pending_r;
   logic [ADDR_WIDTH:0] dma_rd_remaining_r;   
   logic [ADDR_WIDTH:0] cci_wr_remaining_r;   
   logic [ADDR_WIDTH-1:0] rd_addr_r, wr_addr_r;
   
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
   end

   logic rd_fifo_almost_full;
   
   // A request request should happen when there are still
   // cachelines to be read and the read request buffer isn't
   // almost full, and the read data buffer isn't almost full.
   logic cci_rd_en;   
   assign cci_rd_en = cci_rd_remaining_r > 0 && 
		      !cci.c0TxAlmFull &&
		      !rd_fifo_almost_full;

   // Make read requests (on the CCI c0 Tx port).
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 // Only the valid bit needs to be cleared on reset.
         cci.c0Tx.valid <= 1'b0;
      end      
      else begin
	 // Assign the read request signals, which is enabled by cci_rd_en.
         cci.c0Tx <= cci_mpf_genC0TxReadReq(rd_hdr, cci_rd_en);	 
      end
   end

   // Determine when CCI is providing read data.
   logic rd_response_valid;
   assign rd_response_valid = cci_c0Rx_isReadRsp(cci.c0Rx);
   
   logic [$clog2(FIFO_DEPTH):0] rd_fifo_space;

   // The read FIFO is almost full when the number of pending CCI reads
   // is equal to the space left in the FIFO.
   assign rd_fifo_almost_full = cci_rd_pending_r >= rd_fifo_space ? 1'b1 : 1'b0;
   
   // FIFO to buffer memory reads before the AFU reads it from the DMA channel.
   fifo 
     #(
       .WIDTH(512),
       .DEPTH(FIFO_DEPTH)
       )
   rd_fifo 
     (	 
	 .empty(dma.empty),
	 .rd_data(dma.rd_data),
	 .rd_en(dma.rd_en),
	 
	 .full(),
	 .almost_full(),
	 .count(),
	 .space(rd_fifo_space),
	 .wr_data(cci.c0Rx.data),
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
   assign cci_wr_en = dma.wr_en && !cci.c1TxAlmFull && cci_wr_remaining_r > 0;
   
   // Control logic for memory writes
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
         cci.c1Tx.valid <= 1'b0;
      end
      else begin
         cci.c1Tx.valid <= cci_wr_en;	 
	 cci.c1Tx.hdr 	<= wr_hdr;
	 cci.c1Tx.data 	<= dma.wr_data;
      end
   end
   
   logic cci_rd_en_delayed, cci_wr_en_delayed;
   
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
   
   logic rd_starting, waiting_for_first_rd_r;
   assign rd_starting = dma.rd_go || waiting_for_first_rd_r;
   
   logic wr_starting, waiting_for_first_wr_r;
   assign wr_starting = dma.wr_go || waiting_for_first_wr_r;   
   
   always_ff @ (posedge clk or posedge rst) begin
      if (rst == 1'b1) begin
	 cci_rd_remaining_r   <= '0;
	 dma_rd_remaining_r   <= '0;
	 cci_rd_pending_r     <= '0;	 
	 cci_wr_remaining_r   <= '0;

	 cci_rd_en_delayed    <= '0;
	 cci_wr_en_delayed    <= '0;

	 waiting_for_first_rd_r <= '0;
	 waiting_for_first_wr_r <= '0;
      end
      else begin

	 // Initialize read registers on go.
	 if (dma.rd_go) begin
	    rd_addr_r 		 <= dma.rd_addr;
	    cci_rd_remaining_r 	 <= dma.rd_size;
	    dma_rd_remaining_r 	 <= dma.rd_size;
	    waiting_for_first_rd_r <= '1;	    
	 end 

	 // Initialize write registers on go.
	 if (dma.wr_go) begin	    
	    wr_addr_r 		 <= dma.wr_addr;
	    cci_wr_remaining_r 	 <= dma.rd_size;
	    waiting_for_first_wr_r <= '1;	    
	 end

	 // Clear the waiting flags after seeing the first read/write.
	 if (!c0Empty)
	   waiting_for_first_rd_r <= '0;

	 if (!c1Empty)
	   waiting_for_first_wr_r <= '0;

	 // Decrement the number of remaining reads on a valid read.
	 if (dma.rd_en && !dma.empty) begin
	    dma_rd_remaining_r <= dma_rd_remaining_r - 1;	    
	 end

	 // On a CCI read request, update the read registers.
	 if (cci_rd_en) begin
	    rd_addr_r <= rd_addr_r + 1;	    
	    cci_rd_remaining_r <= cci_rd_remaining_r - 1;
	    
	    // Purposesly blocking since this will be upated again below.
	    cci_rd_pending_r = cci_rd_pending_r + 1;	    
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
	 cci_rd_en_delayed <= cci_rd_en;
	 cci_wr_en_delayed <= cci_wr_en;
      end      
   end 

   // Assign DMA interface outputs.
   assign dma.rd_done = !rd_starting && !reads_are_pending ? 1'b1 : 1'b0; 
   assign dma.wr_done = !wr_starting && !writes_are_pending ? 1'b1 : 1'b0;   
   assign dma.full = cci.c1TxAlmFull;
  
endmodule

