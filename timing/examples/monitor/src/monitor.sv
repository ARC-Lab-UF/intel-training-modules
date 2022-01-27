// Greg Stitt
// University of Florida

module fifo_slow
  #(
    parameter WIDTH=8,
    parameter DEPTH=32
    )
   (
    input logic 		   clk,
    input logic 		   rst,
    output logic 		   full,
    input logic 		   wr_en,
    input logic [WIDTH-1:0] 	   wr_data,
    output logic [$clog2(DEPTH):0] count,
    output logic 		   empty, 
    input logic 		   rd_en,
    output logic [WIDTH-1:0] 	   rd_data  
    );

   logic [WIDTH-1:0] 	     ram[DEPTH];
   logic [$clog2(DEPTH)-1:0] wr_addr, rd_addr;
   //logic [$clog2(DEPTH):0]   count;
   logic 		     valid_wr, valid_rd;
   
   always_ff @(posedge clk, posedge rst) begin
      if (rst) begin
	 rd_addr = '0;
	 wr_addr = '0;
	 count = '0;	 
      end
      else begin
	 if (wr_en) begin
	    ram[wr_addr] = wr_data;
	    wr_addr ++;
	    count ++;	    
	 end

	 if (rd_en) begin
	    rd_addr ++;
	    count --;
	 end	   
      end
   end // always_ff @

   assign rd_data = ram[rd_addr];   
   assign valid_wr = wr_en && !full;
   assign valid_rd = rd_en && !empty;
   assign full = count == DEPTH;
   assign empty = count == 0;
    
endmodule // fifo


module fifo
  #(
    parameter WIDTH=8,
    parameter DEPTH=32
    )
   (
    input logic 		   clk,
    input logic 		   rst,
    output logic 		   full,
    input logic 		   wr_en,
    input logic [WIDTH-1:0] 	   wr_data,
    output logic [$clog2(DEPTH):0] count,
    output logic 		   empty, 
    input logic 		   rd_en,
    output logic [WIDTH-1:0] 	   rd_data  
    );

   logic [WIDTH-1:0] 	     ram[DEPTH];
   logic [$clog2(DEPTH)-1:0] wr_addr_r, rd_addr_r;
   logic [$clog2(DEPTH):0]   count_r, next_count;
   logic 		     valid_wr, valid_rd;
   logic signed [1:0] 	     count_update;

   assign count = count_r;
      
   always_ff @(posedge clk, posedge rst) begin
      if (rst) begin
	 rd_addr_r = '0;
	 wr_addr_r = '0;
	 count_r = '0;	 
      end
      else begin
	 count_r <= next_count;
	 
	 if (valid_wr) begin
	    ram[wr_addr_r] = wr_data;
	    wr_addr_r <= wr_addr_r + 1'b1;
	 end
	 	 
	 if (valid_rd) begin	    
	    rd_addr_r <= rd_addr_r + 1'b1;
	 end	   
      end
   end // always_ff @

   // Either increment or decrement the count based on the rd/wr status.
   always_comb begin
      case ({wr_en, rd_en})
	 2'b10 : count_update = 2'(1);
	 2'b01 : count_update = 2'(-1);
	 default : count_update = '0; 	
      endcase
   end
   
   assign next_count = count_r + signed'(count_update);
      
   assign rd_data = ram[rd_addr_r];   
   assign valid_wr = wr_en && !full;
   assign valid_rd = rd_en && !empty;
   assign full = count == DEPTH;
   assign empty = count == 0;
    
endmodule // fifo

module monitor_slow
  #(
    parameter int DATA_WIDTH,
    parameter int COUNTER_WIDTH
    )
   (
    input logic 		     clk,
    input logic 		     rst,
    input logic 		     en,
    output logic 		     ready,
    output logic [COUNTER_WIDTH-1:0] count,
    output logic 		     count_valid
    );

   logic [COUNTER_WIDTH-1:0] 	     count_r;
      
   assign ready = ~rst;
   assign count = count_r;
   assign count_valid = 1'b1;
      
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 count_r <= '0;	 
      end
      else begin
	 if (en) begin
	    count_r <= count_r + 1'b1;	    
	 end
      end
   end  
endmodule
   

module monitor_fast
  #(
    parameter int DATA_WIDTH,
    parameter int COUNTER_WIDTH
    )
   (
    input logic 		     clk,
    input logic 		     rst,
    input logic 		     en,
    output logic 		     ready,
    output logic [COUNTER_WIDTH-1:0] count,
    output logic 		     count_valid
    );

   localparam int 		     CYCLES_BETWEEN_READS = 2;
   localparam int 		     FIFO_DEPTH = 64;
        
   logic [$clog2(CYCLES_BETWEEN_READS)-1:0] cycles_r;
   logic [COUNTER_WIDTH-1:0] 	     count_r;
   logic 			     fifo_rd_en, fifo_empty;
   logic 			     fifo_full, fifo_wr_en;
   logic [$clog2(FIFO_DEPTH):0]      fifo_count;
         
   fifo #(.WIDTH(1), .DEPTH(FIFO_DEPTH)) fifo_ 
     (.wr_en(fifo_wr_en), .full(fifo_full), .wr_data(1'b1), .count(fifo_count),
      .rd_en(fifo_rd_en), .rd_data(), .empty(fifo_empty), .*);

   assign fifo_wr_en = en && ready;   
   assign ready = ~fifo_full;   
   assign count = count_r;

   // There is some latency to update the count, so the count is only valid
   // when the fifo is empty.
   assign count_valid = fifo_empty;
   
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 count_r <= '0;
	 cycles_r <= '0;	 
      end
      else begin
	 fifo_rd_en <= 1'b0;

	 // Whenever the FIFO isn't empty, count up to the CYCLES_BETWEEN_READS
	 if (!fifo_empty) cycles_r <= cycles_r + 1'b1;
	
	 // When reaching the threshold, update count, read from the FIFO,
	 // and reset the multicycle counter.
	 if (cycles_r == CYCLES_BETWEEN_READS-1) begin 
	    count_r <= count_r + 1'b1;
	    fifo_rd_en <= 1'b1;
	    cycles_r <= '0;	    
	 end
      end
   end // always_ff @
      
endmodule
   
module monitor
  #(
    parameter int DATA_WIDTH=8,
    parameter int COUNTER_WIDTH=64
    )
   (
    input logic 		     clk,
    input logic 		     rst,
    input logic 		     en,
    output logic 		     ready,
    output logic [COUNTER_WIDTH-1:0] count,
    output logic 		     count_valid
    );

   //monitor_slow #(.DATA_WIDTH(DATA_WIDTH), .COUNTER_WIDTH(COUNTER_WIDTH)) top (.*);
   monitor_fast #(.DATA_WIDTH(DATA_WIDTH), .COUNTER_WIDTH(COUNTER_WIDTH)) top (.*);
   
endmodule
