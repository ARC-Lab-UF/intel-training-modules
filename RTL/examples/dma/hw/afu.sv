`include "cci_mpf_if.vh"

module afu 
  (
   input clk,
   input rst,
	 mmio_if.user mmio,
	 dma_if.peripheral dma
   );

   //localparam ADDR_WIDTH = dma.getAddrWidth();
   localparam ADDR_WIDTH = dma.ADDR_WIDTH;
   
   // I want to just use dma.addr_t, but apparently
   // either SV or Modelsim doesn't support that. Similarly, I can't
   // just do dma:ADDR_WIDTH without getting errors or warnings about
   // "constant expression cannot contain a hierarchical identifier" in
   // some tools. This is why people hate FPGA tools.
   typedef logic [ADDR_WIDTH-1:0] addr_t;
   typedef logic [ADDR_WIDTH:0] count_t;
   
   logic [63:0] rd_addr, wr_addr;
   count_t 	size;
   //dma.count_t size;
      
   logic 	  go;
   logic 	  done;

   // Each CL has 64 bytes, so the byte index is log2(64) = 6 bits.
   localparam CL_BYTE_INDEX_BITS = 6;
  
   memory_map
     #(
       .ADDR_WIDTH(64),
       .SIZE_WIDTH(ADDR_WIDTH+1)
       )
     memory_map (.*);

   // Converts the virtual byte addresses to CL addresses.
   assign dma.rd_addr = rd_addr[CL_BYTE_INDEX_BITS +: $size(t_cci_clAddr)];
   assign dma.wr_addr = wr_addr[CL_BYTE_INDEX_BITS +: $size(t_cci_clAddr)];
   assign dma.rd_size = count_t'(size);
   assign dma.wr_size = count_t'(size);
   
   assign dma.rd_go = go;
   assign dma.wr_go = go;

   assign dma.rd_en = !dma.empty && !dma.full ? 1'b1 : 1'b0;
   assign dma.wr_en = dma.rd_en;

   assign dma.wr_data = dma.rd_data;
   assign done = dma.wr_done;
            
endmodule




