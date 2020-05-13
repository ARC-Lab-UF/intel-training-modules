
`include "cci_mpf_if.vh"
`include "csr_mgr.vh"

module cci_dma 
  (
   input       clk,
   input       rst,
	       cci_mpf_if.to_fiu fiu,
	       dma_if.dma dma,
	       mmio_if.hal mmio,
  
   input logic c0NotEmpty,
   input logic c1NotEmpty
   );

   localparam int FIFO_DEPTH = 512;  
   
   logic   	  rd_fifo_almost_full;

   // The counts are intentionally one bit larger to support counts from 0
   // to the maximum possible number of cachelines. For example, 8 cachelines
   // requires 4 bits => 4'1000. However, there are 8 different addresses,
   // which only requires 3 bits.
   logic [dma.ADDR_WIDTH:0] cci_rd_remaining_r;
   logic [dma.ADDR_WIDTH:0] cci_rd_pending_r;
   logic [dma.ADDR_WIDTH:0] dma_rd_remaining_r;   
   logic [dma.ADDR_WIDTH:0] cci_wr_remaining_r;
   logic [dma.ADDR_WIDTH-1:0] rd_addr_r, wr_addr_r;
   
   // Create the read header that defines the request to the FIU
   t_cci_mpf_c0_ReqMemHdr rd_hdr;
   t_cci_mpf_ReqMemHdrParams rd_hdr_params;
   
   always_comb begin
      // Tell MPF to use virtual addresses.
      rd_hdr_params = cci_mpf_defaultReqHdrParams(1);
      
      // Tell the FIU to automatically select the communciation channel.
      rd_hdr_params.vc_sel = eVC_VA;
      
      // Always read 1 cache lines. This can certainly be optimized
      // but is kept simple for this training example.
      rd_hdr_params.cl_len = eCL_LEN_1;
      
      // Create the memory read request header.
      rd_hdr = cci_mpf_c0_genReqHdr(eREQ_RDLINE_I,
                                    rd_addr_r,
                                    t_cci_mdata'(0),
                                    rd_hdr_params);
   end
   
   // A request request should happen when there are still
   // cachelines to be read and the read request buffer isn't
   // almost full, and the read data buffer isn't almost full.
   assign cci_rd_en = cci_rd_remaining_r > 0 && 
		      !fiu.c0TxAlmFull &&
		      !rd_fifo_almost_full;
   
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 // Only the valid bit needs to be cleared on reset.
         fiu.c0Tx.valid <= 1'b0;
      end      
      else begin
	 // Assign the read request signals.
         fiu.c0Tx <= cci_mpf_genC0TxReadReq(rd_hdr, cci_rd_en);	 
      end
   end // always_ff @

   logic rd_response_valid;
   assign rd_response_valid = cci_c0Rx_isReadRsp(fiu.c0Rx);

   logic [$clog2(FIFO_DEPTH):0] rd_fifo_space;
   assign rd_fifo_almost_full = cci_rd_pending_r >= rd_fifo_space ? 1'b1 : 1'b0;
   
   // FIFO to buffer read data before it is read from the DMA channel.
   fifo #(
	  .WIDTH(512),
	  .DEPTH(FIFO_DEPTH)
	  )
   rd_fifo (	 
		 .empty(dma.empty),
		 .rd_data(dma.rd_data),
		 .rd_en(dma.rd_en),

		 .full(),
		 .almost_full(),
		 .count(),
		 .space(rd_fifo_space),
		 .wr_data(fiu.c0Rx.data),
		 .wr_en(rd_response_valid),
		 .*
		 );     					       
   
   // Write Port
   // Construct a memory write request header.  
   t_cci_mpf_c1_ReqMemHdr wr_hdr;
   assign wr_hdr = cci_mpf_c1_genReqHdr(eREQ_WRLINE_I,
                                        wr_addr_r,
                                        t_cci_mdata'(0),
                                        cci_mpf_defaultReqHdrParams(1));
      
   assign cci_wr_en = dma.wr_en && !fiu.c1TxAlmFull && cci_wr_remaining_r > 0;
   
   // Control logic for memory writes
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
         fiu.c1Tx.valid <= 1'b0;
      end
      else begin
         fiu.c1Tx.valid <= cci_wr_en;	 
	 fiu.c1Tx.hdr <= wr_hdr;
	 fiu.c1Tx.data <= dma.wr_data;	 
      end
   end // always_ff @
   
   always_ff @ (posedge clk or posedge rst) begin
      if (rst == 1'b1) begin
	 cci_rd_remaining_r <= '0;
	 dma_rd_remaining_r <= '0;
	 cci_rd_pending_r <= '0;	 
	 cci_wr_remaining_r <= '0;	 
      end
      else begin

	 if (dma.rd_go) begin
	    rd_addr_r         <= dma.rd_addr;
	    cci_rd_remaining_r <= dma.rd_size;
	    dma_rd_remaining_r <= dma.rd_size;
	 end 
	 
	 if (dma.wr_go) begin	    
	    wr_addr_r         <= dma.wr_addr;
	    cci_wr_remaining_r <= dma.rd_size;	    
	 end
	 
	 if (dma.rd_en && !dma.empty) begin
	    dma_rd_remaining_r <= dma_rd_remaining_r - 1;	    
	 end
	 
	 if (cci_rd_en) begin
	    rd_addr_r <= rd_addr_r + 1;	    
	    cci_rd_pending_r ++;	    
	    cci_rd_remaining_r <= cci_rd_remaining_r - 1;
	 end
	 
	 if (rd_response_valid) begin
	    cci_rd_pending_r --;	    
	 end
	 
	 if (dma.wr_en && !dma.full) begin
	    wr_addr_r <= wr_addr_r + 1;	    
	 end

	 if (cci_wr_en) begin
	    cci_wr_remaining_r <= cci_wr_remaining_r - 1;	    
	 end
      end      
   end

   assign dma.rd_done = dma_rd_remaining_r == 0 && !c0NotEmpty ? 1'b1 : 1'b0; 
   assign dma.wr_done = cci_wr_remaining_r == 0 && !c1NotEmpty ? 1'b1 : 1'b0;
   assign dma.full = fiu.c1TxAlmFull;

   //=========================================================
   // Convert CCI-P MMIO to simpler interface
   
   assign mmio.rd_en = cci_csr_isRead(fiu.c0Rx);
   assign mmio.wr_en = cci_csr_isWrite(fiu.c0Rx);
   assign mmio.rd_addr = cci_csr_getAddress(fiu.c0Rx);
   assign mmio.wr_data = 64'(fiu.c0Rx.data);
   assign mmio.wr_addr = cci_csr_getAddress(fiu.c0Rx);

   assign fiu.c2Tx.data = mmio.rd_data;
   
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 fiu.c2Tx.mmioRdValid <= '0;
      end
      else begin

	 fiu.c2Tx.mmioRdValid <= '0;
	 
	 if (cci_csr_getAddress(fiu.c0Rx) >= mmio.START_ADDR &&
	     cci_csr_getAddress(fiu.c0Rx) <= mmio.END_ADDR) begin
	    fiu.c2Tx.mmioRdValid <= mmio.rd_en;
	 end
	 
	 fiu.c2Tx.hdr.tid <= cci_csr_getTid(fiu.c0Rx);	 
      end
   end 
   
endmodule

