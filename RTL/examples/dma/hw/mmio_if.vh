`ifndef MMIO_IF
 `define MMIO_IF

interface mmio_if #(parameter int DATA_WIDTH, 
		    parameter int ADDR_WIDTH,
		    parameter int START_ADDR,
		    parameter int END_ADDR);   
   
   logic [DATA_WIDTH-1:0] rd_data;
   logic [ADDR_WIDTH-1:0] rd_addr;
   logic                  rd_en;
   
   logic [DATA_WIDTH-1:0] wr_data;
   logic [ADDR_WIDTH-1:0] wr_addr;
   logic                  wr_en;
   
   modport hal (
		input  rd_data,
		output rd_addr, rd_en, wr_data, wr_addr, wr_en
		);
   
   modport user (
		 output rd_data,
		 input 	rd_addr, rd_en, wr_data, wr_addr, wr_en
		);
   
endinterface // mmio_if

`endif //  `ifndef MMIO_IF

   
