`ifndef DMA_IF
`define DMA_IF

interface dma_if #(parameter int DATA_WIDTH, 
		   parameter int ADDR_WIDTH);

   typedef logic [ADDR_WIDTH-1:0] addr_t;
   typedef logic [ADDR_WIDTH:0] count_t;
   
   logic 			rd_go, rd_done;
   logic 			wr_go, wr_done;
   count_t  	 rd_size, wr_size;
   
   logic rd_en;
   logic [DATA_WIDTH-1:0] rd_data;
   addr_t rd_addr;
   logic 		  empty;

   logic wr_en;
   logic [DATA_WIDTH-1:0] wr_data;
   addr_t wr_addr;
   logic 		  full;

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
