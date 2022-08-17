// Greg Stitt
// University of Florida

module high_fanout_add_slow
  #(
    parameter int DATA_WIDTH,
    parameter int NUM_ADDERS
    )
   (
    input logic 		  clk,
    input logic 		  rst,
    input logic [DATA_WIDTH-1:0]  in,
    output logic [DATA_WIDTH-1:0] out[NUM_ADDERS]
    );

   logic [DATA_WIDTH-1:0] in_r;
   // We don't need this register here, but to make all the different modules
   // look the same, we add it for consistency. Also, we use the dont_replicate
   // synthesis attribute to make sure Quartus doesn't automatically duplicate
   // the register for us. In many cases, we want Quartus to duplicate the
   // register, but here we need a baseline that is guaranteed not to have
   // duplicated registers in order to show the benefits of duplication.
   (* dont_replicate *) logic [DATA_WIDTH-1:0] 	 add_in_r;
   
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= '0;
	 add_in_r <= '0;	 
      end
      else begin
	 in_r <= in;
	 add_in_r <= in_r;	 
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= add_in_r + DATA_WIDTH'(i);
      end
   end
endmodule


module high_fanout_add_auto_reg_dup
  #(parameter int DATA_WIDTH,
    parameter int NUM_ADDERS,
    parameter int MAX_FANOUT)
   (
    input logic 		  clk,
    input logic 		  rst,
    input logic [DATA_WIDTH-1:0]  in,
    output logic [DATA_WIDTH-1:0] out[NUM_ADDERS]
    );
      
   logic [DATA_WIDTH-1:0] 	  in_r;

   // In many cases, a synthesis tool will perform register duplication
   // automatically depending on the timing constraint.
   // If we want to control the amount of register duplication, Quartus
   // allows us to specify a maxfan attribute for the register variable.
   // The corresponding integer, e.g. MAX_FANOUT, creates a threshold where 
   // any time the amount of fanout from the add_in_r register increases past 
   // the threshold, Quartus will create another duplicated version of the
   // register.
   (* maxfan = MAX_FANOUT *) logic [DATA_WIDTH-1:0] 	 add_in_r;

   // Quartus also allows for synthesis settings to be specified in a string
   // following the variable declaration, as shown below. For this specific
   // example, this won't work because the attribute is specified in a string.
   // That string isn't elaborated, so MAX_FANOUT is never replaced with the 
   // corresponding integer, which will cause Quartus to report the warning:
   // Warning(19887): Value '"MAX_FANOUT"' for assignment 'maxfan' is an invalid value and assignment is being ignored.
   //
   // logic [DATA_WIDTH-1:0] 	 add_in_r /* synthesis maxfan = MAX_FANOUT */;
    
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= '0;	 
      end
      else begin
	 in_r <= in;
	 add_in_r <= in_r;
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= add_in_r + DATA_WIDTH'(i);
      end
   end
endmodule


module high_fanout_add_manual_reg_dup
  #(
    parameter int DATA_WIDTH,
    parameter int NUM_ADDERS,
    parameter int MAX_FANOUT
    )
   (
    input logic 		  clk,
    input logic 		  rst,
    input logic [DATA_WIDTH-1:0]  in,
    output logic [DATA_WIDTH-1:0] out[NUM_ADDERS]
    );
   
   localparam int 		  NUM_DUP_REGS = int'($ceil(NUM_ADDERS / real'(MAX_FANOUT)));

   logic [DATA_WIDTH-1:0] 	  in_r;
   
   // One tricky part of manual register duplication is that synthesis tools
   // look for identical registers and then remove them to save resources.
   // Normally, eliminating identical registers is a good thing, with the
   // exception of when we are purposely duplicating them for timing 
   // optimization.
   //
   // To prevent a synthesis tool from removing duplicate registeres, we need
   // to tell it explicitly not to remove them. Unfortunately, the technique
   // for informing synthesis is tool dependent, so this example won't work
   // with every tool. We instead focus solely on Quartus.

   // dont_merge is an attribute that prevents Quartus from merging the 
   // specified registers.
   (* dont_merge *) logic [DATA_WIDTH-1:0] 	 add_in_r[NUM_DUP_REGS];

   // The following is an equivalent way of accomplishing the same thing, but
   // where we are specifying synthesis setting in a comment following the
   // register declaration.
   //logic [DATA_WIDTH-1:0] 	 add_in_r[NUM_DUP_REGS] /* synthesis dont_merge */;
   
   // In some cases, we might also want to prevent a register from being
   // optimized away for other regions, or retiming. We can prevent this
   // with the preserve attribute, using either of the following techniques:
   // NOTE: It appears that some of the attributes behave differently in
   // different versions of Quartus. For example, in some versions you might
   // need the dont_retime attribute.
   //
   //(* preserve, dont_merge *) logic [DATA_WIDTH-1:0] 	 add_in_r[NUM_DUP_REGS];
   //logic [DATA_WIDTH-1:0] 	 add_in_r[NUM_DUP_REGS] /* synthesis preserve dont_merge */;   

   // In some cases (e.g. debugging), we might want to prevent Quartus from
   // removing logic for any reason, which we can accomplish with
   // preserve_for_debugging. Note that this attribute is only supported by
   // newer version of the Quartus.
   //logic [DATA_WIDTH-1:0] 	 add_in_r[NUM_DUP_REGS] /* synthesis preserve_for_debugging */;   
   //(* preserve_for_debug *) logic [DATA_WIDTH-1:0] 	 add_in_r[NUM_DUP_REGS];
     
   // For more details of the other possible options, see the following:
   // https://www.intel.la/content/dam/www/programmable/us/en/pdfs/literature/ug/ug-qpp-compiler.pdf
   //
   // For details of how to do the same in other synthesis tools:
   // https://www.xilinx.com/support/documentation/sw_manuals/ug1192-xilinx-design-for-intel.pdf
       
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= '0;	 
      end
      else begin
	 in_r <= in;
	 // Manually create the duplicated registers.
	 for (int i=0; i < NUM_DUP_REGS; i++) add_in_r[i] <= in_r;
	 // Manually connect the adder inputs to duplicated registers.
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= add_in_r[i/MAX_FANOUT] + DATA_WIDTH'(i); 
      end
   end
endmodule // high_fanout_add_manual_reg_dup


module high_fanout_add
  #(
    parameter int DATA_WIDTH=8,
    parameter int NUM_ADDERS=4,
    parameter int MAX_FANOUT=2
    )
   (
    input logic 		 clk,
    input logic 		 rst,
    input logic [DATA_WIDTH-1:0] in,
    // HUGE GOTCHA: input attached to output of internal module with no errors.
    //input logic [DATA_WIDTH-1:0] out[NUM_ADDERS]
    output logic [DATA_WIDTH-1:0] out[NUM_ADDERS]
    );

   /*high_fanout_add_manual_reg_dup #(.DATA_WIDTH(DATA_WIDTH), 
   				    .NUM_ADDERS(NUM_ADDERS),
   				    .MAX_FANOUT(MAX_FANOUT)) top (.*);*/

   /*high_fanout_add_auto_reg_dup #(.DATA_WIDTH(DATA_WIDTH), 
   				  .NUM_ADDERS(NUM_ADDERS),
				  .MAX_FANOUT(MAX_FANOUT)) top (.*);*/

   
   high_fanout_add_slow #(.DATA_WIDTH(DATA_WIDTH),
			  .NUM_ADDERS(NUM_ADDERS)) top (.*);
  
 
endmodule
