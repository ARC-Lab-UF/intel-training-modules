module bram
  #(
    parameter int data_width,
    parameter int addr_width
    )
   (
    input logic 		  clk,

    // Write port
    input 			  wr_en,
    input [addr_width-1:0] 	  wr_addr,
    input [data_width-1:0] 	  wr_data,

    // Read port
    input [addr_width-1:0] 	  rd_addr,
    output logic [data_width-1:0] rd_data
    );
   
   logic [data_width-1:0] 	  mem [2**addr_width];
   logic [data_width-1:0] 	  mem_data;
   
   always @ (posedge clk) begin
      if (wr_en) begin
         mem[wr_addr] = wr_data;
      end

      // This statement ensures the RAM uses the old data during a read/write conflict.
      // Mem_data is the output of the block RAM by itself.
      mem_data <= mem[rd_addr];

      // Register the memory output. This isn't necessary for a block RAM but 
      // can often eliminating timing-closure bottlenecks.
      rd_data <= mem_data; 
   end
endmodule
