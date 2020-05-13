
module memory_map
  #(
    parameter int ADDR_WIDTH,
    parameter int SIZE_WIDTH
    )
   (
   input 	       clk,
   input 	       rst, 
   
		       mmio_if.user mmio,
   
   output logic [ADDR_WIDTH-1:0] rd_addr, wr_addr,
   output logic [SIZE_WIDTH-1:0] size,
   output logic        go,
   input logic 	       done   
   );
   
   // =============================================================//   
   // MMIO write code
   // =============================================================//     
   always_ff @(posedge clk or posedge rst) begin 
      if (rst) begin
	 go       <= '0;
	 rd_addr  <= '0;
	 wr_addr  <= '0;	     
	 size     <= '0;
      end
      else begin
	 go <= '0;
	 
         if (mmio.wr_en == 1'b1) begin
            case (mmio.wr_addr)
              16'h0050: go       <= mmio.wr_data[0];
	      16'h0052: rd_addr  <= mmio.wr_data[$size(rd_addr)-1:0];
	      16'h0054: wr_addr  <= mmio.wr_data[$size(wr_addr)-1:0];
	      16'h0056: size     <= mmio.wr_data[$size(size)-1:0];
            endcase
         end
      end
   end

   // ============================================================= 		    
   // MMIO read code
   // ============================================================= 		    
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 mmio.rd_data <= '0;
      end
      else begin             
         if (mmio.rd_en == 1'b1) begin
	    
	    mmio.rd_data <= '0;
	    
            case (mmio.rd_addr)

	      16'h0052: mmio.rd_data[$size(rd_addr)-1:0] <= rd_addr;
	      16'h0054: mmio.rd_data[$size(wr_addr)-1:0] <= wr_addr;
	      16'h0056: mmio.rd_data[$size(size)-1:0] <= size;     	     
	      16'h0058: mmio.rd_data[0] <= done;
	      
	      // If the processor requests an address that is unused, return 0.
              default:  mmio.rd_data <= 64'h0;
            endcase
         end
      end
   end
endmodule
