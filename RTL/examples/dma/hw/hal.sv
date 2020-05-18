// Greg Stitt
// University of Florida

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

   // Instantiate the DMA interface signals.
   dma_if 
     #(
       .DATA_WIDTH($size(t_ccip_clData)),
       .ADDR_WIDTH($size(t_ccip_clAddr))
       ) dma();

   // Instantiate the MMIO interface signals.
   // TODO: Replace hardcoded values with $size of CCI signals.
   mmio_if 
     #(
       .DATA_WIDTH(64),
       .ADDR_WIDTH(16),
       .START_ADDR(MMIO_START_ADDR),
       .END_ADDR(MMIO_END_ADDR)
       ) mmio();

  
   // Convert the DMA interface into CCI-P
   cci_dma dma_ctrl
     (
      .cci(cci),
      .dma(dma),
      .c0Empty,
      .c1Empty,
      .*
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
