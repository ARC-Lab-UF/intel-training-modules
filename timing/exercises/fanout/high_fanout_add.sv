module high_fanout_slow
  #(parameter int DATA_WIDTH,
    parameter int NUM_ADDERS,
    parameter int REG_DUP_AMOUNT)
   (
    input logic clk,
    input logic rst,
    input logic [DATA_WIDTH-1:0] in,
    output logic [DATA_WIDTH-1:0] out[NUM_ADDERS]
    );

   //(* maxfan = 1024 *) logic [DATA_WIDTH-1:0] in_r;
   logic [DATA_WIDTH-1:0] in_r; 
   
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= '0;	 
      end
      else begin
	 in_r <= in;
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= in_r + DATA_WIDTH'(i); 
      end
   end
endmodule


module high_fanout_manual_reg_dup
  #(parameter int DATA_WIDTH,
    parameter int NUM_ADDERS,
    parameter int MAX_FANOUT=2048)
   (
    input logic 		 clk,
    input logic 		 rst,
    input logic [DATA_WIDTH-1:0] in,
    output logic [DATA_WIDTH-1:0] out[NUM_ADDERS]
    );

   
   localparam int 		  NUM_DUP_REGS = int'($ceil(NUM_ADDERS / MAX_FANOUT));

   $error("%0d, %0d, %0d", NUM_ADDERS, MAX_FANOUT, NUM_DUP_REGS);
      
   logic [DATA_WIDTH-1:0] 	 in_r;
      
   // https://www.intel.la/content/dam/www/programmable/us/en/pdfs/literature/ug/ug-qpp-compiler.pdf

   // Syntax errors?
   //(* preserve dont_merge *) logic [DATA_WIDTH-1:0] 	 add_in_r[REG_DUP_AMOUNT];
   
   // Doesn't work.
   //logic [DATA_WIDTH-1:0] 	 add_in_r[REG_DUP_AMOUNT] /* synthesis preserve_for_debugging */;   
   //(* preserve_for_debug *) logic [DATA_WIDTH-1:0] 	 add_in_r[REG_DUP_AMOUNT];
  
 
   // Works
   //(* preserve *) (* dont_merge *) logic [DATA_WIDTH-1:0] 	 add_in_r[REG_DUP_AMOUNT];

   //logic [DATA_WIDTH-1:0] 	 add_in_r[REG_DUP_AMOUNT] /* synthesis dont_merge */;
   (* dont_merge *) logic [DATA_WIDTH-1:0] 	 add_in_r[NUM_DUP_REGS];
    
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= '0;	 
      end
      else begin
	 in_r <= in;
	 for (int i=0; i < NUM_DUP_REGS; i++) add_in_r[i] <= in_r;
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= add_in_r[i/MAX_FANOUT] + DATA_WIDTH'(i); 
      end
   end
endmodule // high_fanout_manual_regdup


module high_fanout_manual_reg_dup1
  #(parameter int DATA_WIDTH,
    parameter int NUM_ADDERS,
    parameter int REG_DUP_AMOUNT)
   (
    input logic 		 clk,
    input logic 		 rst,
    input logic [DATA_WIDTH-1:0] in,
    output logic [DATA_WIDTH-1:0] out[NUM_ADDERS]
    );

   logic [DATA_WIDTH-1:0] 	 in_r;

   // https://www.intel.la/content/dam/www/programmable/us/en/pdfs/literature/ug/ug-qpp-compiler.pdf

   // Syntax errors?
   //(* preserve dont_merge *) logic [DATA_WIDTH-1:0] 	 add_in_r[REG_DUP_AMOUNT];
   
   // Doesn't work.
   //logic [DATA_WIDTH-1:0] 	 add_in_r[REG_DUP_AMOUNT] /* synthesis preserve_for_debugging */;   
   //(* preserve_for_debug *) logic [DATA_WIDTH-1:0] 	 add_in_r[REG_DUP_AMOUNT];
  
 
   // Works
   //(* preserve *) (* dont_merge *) logic [DATA_WIDTH-1:0] 	 add_in_r[REG_DUP_AMOUNT];

   //logic [DATA_WIDTH-1:0] 	 add_in_r[REG_DUP_AMOUNT] /* synthesis dont_merge */;
   (* dont_merge *) logic [DATA_WIDTH-1:0] 	 add_in_r[REG_DUP_AMOUNT];
    
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= '0;	 
      end
      else begin
	 in_r <= in;
	 for (int i=0; i < REG_DUP_AMOUNT; i++) add_in_r[i] <= in_r;
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= add_in_r[i/REG_DUP_AMOUNT] + DATA_WIDTH'(i); 
      end
   end
endmodule // high_fanout_manual_regdup




module high_fanout_add
  #(parameter int DATA_WIDTH=8,
    parameter int NUM_ADDERS=4,
    parameter int REG_DUP_AMOUNT=2)
   (
    input logic 		 clk,
    input logic 		 rst,
    input logic [DATA_WIDTH-1:0] in,
    // HUGE GOTCHA: input attached to output of internal module with no errors.
    //input logic [DATA_WIDTH-1:0] out[NUM_ADDERS]
    output logic [DATA_WIDTH-1:0] out[NUM_ADDERS]
    );

   high_fanout_manual_reg_dup #(.DATA_WIDTH(DATA_WIDTH), 
   			       .NUM_ADDERS(NUM_ADDERS),
			       .MAX_FANOUT(8)) top (.*);
   
//   high_fanout_manual_reg_dup1 #(.DATA_WIDTH(DATA_WIDTH), 
//   			       .NUM_ADDERS(NUM_ADDERS),
//			       .REG_DUP_AMOUNT(REG_DUP_AMOUNT)) top (.*);
  
   //high_fanout_slow #(.DATA_WIDTH(DATA_WIDTH),
//		      .NUM_ADDERS(NUM_ADDERS),
//		      .REG_DUP_AMOUNT(REG_DUP_AMOUNT)) top (.*);
  
 
endmodule
