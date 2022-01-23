// Greg Stitt
// University of Florida
//
// TODO: Make sure the multiple_add_module at the bottom of the file is using
// the multiple_add_slow module. Then, compile the design, run the timing 
// analyzer, and identify the timing bottlenecks. Next, comment out the
// multiple_add_slow instantiation and uncomment multiple_add_auto_reg_dup1.
// Repeat the same process as before and notice the change in clock
// frequency. Repeat for all the different modules.
//
// NOTE: The resulting clock frequencies from my tested experiments are included
// but are likely to vary depending on your version of Quartus.
//
//
// Module Descriptions:  This following modules perform NUM_ADDERS separate 
// additions of a single input with different constants. These adders create
// a large fanout from an input register, which becomes the primary timing
// bottleneck. To resolve this bottleneck, we perform different techniques for
// register duplication to meet the provided clock constraint of 200 MHz.

//===================================================================
// Parameter Description
// DATA_WIDTH : The data width (number of bits) of the input and output
// NUM_ADDERS : The number of adds to perform.
// MAX_FANOUT : The maximum fanout before register duplication occurs. Does not
//              apply to all the modules.
//===================================================================

//===================================================================
// Interface Description
// clk  : Clock input
// rst  : Reset input (active high)
// in   : An DATA_WIDTH-bit input to add with different constants
// out  : An array of sums of in with different constants
//===================================================================


// Module: multiple_add_slow
// Description: This module makes no attempts at register duplication, and
// prohibits Quartus from doing it automatically.

// Resulting clocks:
// Slow 1200mV 85C Model Fmax: 185.80 MHz (FAILS)
// Slow 1200mV 0C Model Fmax: 201.86 MHz

module multiple_add_slow
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

   // Register the input. We technically don't need this, but without it, some
   // of the techniques would be increasing fanout of components that
   // instantiate this module. By registering the input, all fanout is
   // contained within this module.
   logic [DATA_WIDTH-1:0] in_r;

   // We don't need this register here, but to make all the different modules
   // look the same, we add it for consistency. Also, we use the dont_replicate
   // attribute to make sure Quartus doesn't automatically duplicate
   // the register for us. In many cases, we want Quartus to duplicate the
   // register, but here we need a baseline that is guaranteed not to have
   // duplicated registers in order to show the benefits of duplication.
   (* dont_replicate *) logic [DATA_WIDTH-1:0] 	 add_in_r;
   
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 in_r <= '0;
	 add_in_r <= '0;	 
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= '0;
      end
      else begin
	 in_r <= in;
	 add_in_r <= in_r;
	 
	 // Perform NUM_ADDERS additions of the input with different constants.
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= add_in_r + DATA_WIDTH'(i);
      end
   end
endmodule


// Module: multiple_add_auto_reg_dup1
// Description: This module leaves it up to synthesis about whether or not to
// duplicate registers, and by how much. The code is identical to the slow
// version, but without the dont_replicate attribute.

// Resulting clocks:
// Slow 1200mV 85C Model Fmax: 185.80 MHz (FAILS)
// Slow 1200mV 0C Model Fmax: 201.86 MHz
// These are identical to the previous module, which suggests Quartus isn't
// automatically applying any register duplication in my tests.

module multiple_add_auto_reg_dup1
  #(parameter int DATA_WIDTH,
    parameter int NUM_ADDERS)
   (
    input logic 		  clk,
    input logic 		  rst,
    input logic [DATA_WIDTH-1:0]  in,
    output logic [DATA_WIDTH-1:0] out[NUM_ADDERS]
    );
      
   logic [DATA_WIDTH-1:0] 	  in_r;
   logic [DATA_WIDTH-1:0] 	  add_in_r;

   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
 	 in_r <= '0;
	 add_in_r <= '0;	 
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= '0;	 
      end
      else begin
	 in_r <= in;
	 add_in_r <= in_r;
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= add_in_r + DATA_WIDTH'(i);
      end
   end
endmodule


// Module: multiple_add_auto_reg_dup2
// Description: This module uses the same code as the previous module, but
// tells Quartus when to apply duplication based on the MAX_FANOUT parameter.

// Resulting clocks:
// Slow 1200mV 85C Model Fmax: 199.6 MHz (FAILS)
// Slow 1200mV 0C Model Fmax: 217.06 MHz

module multiple_add_auto_reg_dup2
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
	 in_r <= '0;
	 add_in_r <= '0;	 
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= '0;	 
      end
      else begin
	 in_r <= in;
	 add_in_r <= in_r;
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= add_in_r + DATA_WIDTH'(i);
      end
   end
endmodule


// Module: multiple_add_manual_reg_dup
// Description: This module manually applies register duplication by explicitly
// instantiating the duplicated registers and then adding attributes to prohibit
// Quartus from removing them. 
//
// NOTE: Usually, this manual strategy is not needed, but in some cases manual 
// duplication provides better results.

// Resulting clocks:
// Slow 1200mV 85C Model Fmax: 213.68 MHz
// Slow 1200mV 0C Model Fmax: 233.54 MHz

module multiple_add_manual_reg_dup
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

   // Some versions of quartus don't support $ceil. Prime Pro does, but older
   // version do not.
   //localparam int 		  NUM_DUP_REGS = int'($ceil(NUM_ADDERS / real'(MAX_FANOUT)));

   // Workaround for versions of Quartus that don't support $ceil.
   localparam int 		  NUM_DUP_REGS = NUM_ADDERS % MAX_FANOUT == 0 ? NUM_ADDERS / MAX_FANOUT : NUM_ADDERS / MAX_FANOUT + 1;
   
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
	 in_r <= '0;
	 for (int i=0; i < NUM_DUP_REGS; i++) add_in_r[i] <= '0;
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
endmodule // multiple_add_manual_reg_dup


// Module: multiple_add_manual_reg_tree
// Description: This module hierarchly applies register duplication across
// multiple levels to avoid the fanout at the top level becoming excessive.
// It is hardcoded to support 64 adders through a 2-level register tree. In the
// first level in_r fans out to 4 registers (add_in_level1_r). Those 4 registers
// each fanout to 4 registers each, and 16 total (add_in_level2_r). The
// tradeoff of this register tree approach is that it incurs one more cycle
// of latency, but in some cases this can be very attractive for a significant
// improvement in clock frequency.

// Resulting clocks:
// Slow 1200mV 85C Model Fmax: 222.82 MHz
// Slow 1200mV 0C Model Fmax: 246.12 MHz

module multiple_add_manual_reg_tree
  #(
    parameter int DATA_WIDTH
    )
   (
    input logic 		  clk,
    input logic 		  rst,
    input logic [DATA_WIDTH-1:0]  in,
    output logic [DATA_WIDTH-1:0] out[64]
    );

   localparam int 		  NUM_ADDERS = 64;
   
   logic [DATA_WIDTH-1:0] 	  in_r;

   // Add three levels of register duplication. This prevents excessive fanout
   // at the top level.
   (* dont_merge *) logic [DATA_WIDTH-1:0] 	 add_in_level1_r[4];
   (* dont_merge *) logic [DATA_WIDTH-1:0] 	 add_in_level2_r[16];
       
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
	 in_r <= '0;	 
	 for (int i=0; i < 4; i++) add_in_level1_r[i] <= '0;
	 for (int i=0; i < 16; i++) add_in_level2_r[i] <= '0;	 
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= '0;	 
      end
      else begin
	 in_r <= in;
	 
	 // Manually create the register duplication hierarchy.
	 for (int i=0; i < 4; i++) add_in_level1_r[i] <= in_r;
	 for (int i=0; i < 16; i++) add_in_level2_r[i] <= add_in_level1_r[i/4];
	 
	 // Manually connect the adder inputs to duplicated registers.
	 for (int i=0; i < NUM_ADDERS; i++) out[i] <= add_in_level2_r[i/4] + DATA_WIDTH'(i); 
      end
   end
endmodule // multiple_add_manual_reg_tree


// Module: multiple_add_
// Description: This module provides a top level for synthesizing each
// implementation. Simply uncomment the instantiation you wish to test and
// recompile in Quartus.

module multiple_add
  #(
    parameter int DATA_WIDTH=32,
    parameter int NUM_ADDERS=64,
    parameter int MAX_FANOUT=4
    )
   (
    input logic 		 clk,
    input logic 		 rst,
    input logic [DATA_WIDTH-1:0] in,
    output logic [DATA_WIDTH-1:0] out[NUM_ADDERS]
    );

   multiple_add_slow #(.DATA_WIDTH(DATA_WIDTH),
		       .NUM_ADDERS(NUM_ADDERS)) top (.*);

   /*multiple_add_auto_reg_dup1 #(.DATA_WIDTH(DATA_WIDTH), 
				.NUM_ADDERS(NUM_ADDERS)) top (.*);*/

   /*multiple_add_auto_reg_dup2 #(.DATA_WIDTH(DATA_WIDTH), 
				.NUM_ADDERS(NUM_ADDERS),
				  .MAX_FANOUT(MAX_FANOUT)) top (.*);*/

   /*multiple_add_manual_reg_dup #(.DATA_WIDTH(DATA_WIDTH), 
   				 .NUM_ADDERS(NUM_ADDERS),
   				 .MAX_FANOUT(MAX_FANOUT)) top (.*);*/

   // NOTE: NUM_ADDERS hardcoded to 64 for this example. MAX_FANOUT not used.
   /*multiple_add_manual_reg_tree #(.DATA_WIDTH(DATA_WIDTH)) top (.*);*/
   
endmodule
