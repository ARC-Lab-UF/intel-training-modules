// Greg Stitt
// University of Florida

module fifo #(parameter int WIDTH,
	      parameter int DEPTH,
	      parameter int ALMOST_FULL_COUNT=DEPTH)
   (
    input logic 		   clk,
    input logic 		   rst,
    input logic 		   rd_en,
    input logic 		   wr_en,
    output logic 		   empty,
    output logic 		   full,
    output logic 		   almost_full,
    output logic [$clog2(DEPTH):0] count,
    output logic [$clog2(DEPTH):0] space,
    input [WIDTH-1:0] 		   wr_data,
    output logic [WIDTH-1:0] 	   rd_data
    );

   localparam ADDR_WIDTH = $clog2(DEPTH);
   
   logic [WIDTH-1:0] 		   mem [2**ADDR_WIDTH];
   logic [ADDR_WIDTH-1:0] 	   wr_addr, rd_addr, rd_addr_adjusted;
   logic [$clog2(DEPTH):0] 	   count_r, next_count;
   logic [$clog2(DEPTH):0] 	   space_r, next_space;
   logic 			   next_full, next_almost_full, next_empty;
   logic 			   valid_rd, valid_wr;
      
   // Create a block RAM for the FIFO.
   // NOTE: This provides the new data when a write occurs to the
   // read address. This is not the recommended way of using a block
   // RAM because it can result in a slower clock.
   always @ (posedge clk) begin
      if (valid_wr) begin
         mem[wr_addr] = wr_data;
      end
      
      rd_data = mem[rd_addr_adjusted];      
   end

   // Adjust the read address to prefetch the next data from the BRAM
   // on a valid read. This is necessary to have the data appear on the
   // read port before receiving the rd_en.
   assign rd_addr_adjusted = (valid_rd == 1'b0) ? rd_addr : ADDR_WIDTH'(rd_addr+1);

   // Safety checks to prevent reads when empty and writes when full.
   assign valid_wr = wr_en && ~full;
   assign valid_rd = rd_en && ~empty;
   
   always_ff @ (posedge clk or posedge rst) begin     
      if (rst) begin
	 wr_addr     <= '0;
	 rd_addr     <= '0;
	 count_r     <= '0;
	 space_r     <= DEPTH;	   
	 full 	     <= '1;
	 almost_full <= '1;	   
	 empty 	     <= '1;	   
      end
      else begin
	 if (valid_rd)
	   rd_addr <= rd_addr + 1'b1;
	      	 
	 if (valid_wr)
	   wr_addr <= wr_addr + 1'b1;
	 	 	 
	 count_r     <= next_count;	   
	 space_r     <= next_space;	   
	 full 	     <= next_full;
	 almost_full <= next_almost_full;
	 empty 	     <= next_empty;	   
      end
   end // always_ff @
   
   always_comb begin

      next_full 	= 1'b0;
      next_empty 	= 1'b0;
      next_almost_full 	= 1'b0;
      next_count 	= count_r;
      next_space 	= space_r;

      // Update the count and space on valid reads/writes.
      if (valid_rd && !valid_wr) begin
	 next_count--;
	 next_space++;       
      end
      else if (!valid_rd && valid_wr) begin
	 next_count++;
	 next_space--;	 
      end;
      
      if (next_count >= ALMOST_FULL_COUNT)
	next_almost_full = 1'b1;
      
      if (next_count == DEPTH)
	next_full = 1'b1;
      
      if (next_count == 0)
	next_empty = 1'b1;         
    
   end // always_comb

   assign count = count_r;
   assign space = space_r;
      
endmodule     
