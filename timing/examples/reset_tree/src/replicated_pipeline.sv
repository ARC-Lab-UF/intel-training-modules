// Greg Stitt 
// University of Florida
//
// This example illustrates how to replace a high fanout reset signal with
// a hierarchy of registered reset signals (i.e. a reset tree). The concept is
// similar to the register tree used for register duplication, where instead of
// a single reset with a massive fanout, we instead use a tree to greatly
// restrict the maximum fanout to a small number across multiple cycled by using
// a tree.
//
// This technique is usually not beneficial for small designs, so this example 
// is simply for illustration.
//
// NOTE: There are some risks in using this approach. First, it is usually very
// important that all leaves of the register tree receive the reset at the
// same time. In addition, there is now a latency in resetting the design. The
// reset signal only has to be high for 1 cycle, but the control for the circuit
// must take into account the reset latency and restrict the usage until that
// latency has passed. For these reasons, this strategy should only be used
// when other reset optimization techniques are still causing a bottleneck.
//
// In this specific example, we create a simple pipeline that calculates a 
// polynomial. We then replicate that pipeline in separate modules. In one
// module, we simply use a single reset that fans out to all replications. In
// a second module, we create a reset register tree, where each leaf of the tree
// resets a separate pipeline instance.

// Module: polynomial_pipe
// Description: A simple pipeline that implements the polynomial:
//   f(x) = 10*x^3 + 20*x^2 + 30*x + 40
// across 4 cycles.

module polynomial_pipe
   #(parameter int WIDTH)
   (
    input logic                clk,
    input logic                rst,
    input logic                en,
    input logic [WIDTH-1:0]    x,
    output logic [4*WIDTH-1:0] out
    );

   localparam int            LATENCY = 4;

   logic [4*WIDTH-1:0]       x_pow2, x_pow3, t1, t2, t3;  
   logic [4*WIDTH-1:0]       sum_t3_t4, sum_t2_t3_t4;
        
   // f(x) = 10*x^3 + 20*x^2 + 30*x + 40
   
   always_ff @(posedge clk or posedge rst) begin
      if (rst == 1'b1) begin
         t1 <= '0;
         t2 <= '0;
         t3 <= '0;
         x_pow2 <= '0;
         x_pow3 <= '0;
         sum_t2_t3_t4 <= '0;
         sum_t3_t4 <= '0;        
      end
      else begin
         if (en == 1'b1) begin
            // Cycle 1
            x_pow2 <= x * x;
            t3 <= WIDTH'(30) * x;
            
            // Cycle 2
            x_pow3 <= x * x_pow2;
            t2 <= WIDTH'(20) * x_pow2;
            sum_t3_t4 <= t3 + WIDTH'(40);        
            
            // Cycle 3
            t1 <= WIDTH'(10) * x_pow3;
            sum_t2_t3_t4 <= t2 + sum_t3_t4;
            
            // Cycle 4   
            out <= t1 + sum_t2_t3_t4;
         end
      end            
   end   
endmodule


// Module: replicated_pipeline_full_reset
// Description: This module replicates the polynomial_pipe, while using the
// standard reset strategy of fanning out the reset to all replicated pipelines.
   
module replicated_pipeline_full_reset
   #(parameter int WIDTH=8,
     parameter int NUM_REPLICATIONS=8)
   (
    input logic              clk,
    input logic              rst,
    input logic [WIDTH-1:0]  in[NUM_REPLICATIONS],
    input logic              valid_in,
    output logic [4*WIDTH-1:0] out[NUM_REPLICATIONS],
    output logic             valid_out
    );

   localparam int            LATENCY=4;
   logic [0:LATENCY-1]       valid_delay_r;

   // Quartus Prime requires the genvar outside the loop. Prime Pro does not.
   genvar i;
   generate
      for (i=0; i < NUM_REPLICATIONS; i++) begin : l_pipelines
         polynomial_pipe #(.WIDTH(WIDTH)) pipe (.x(in[i]), .out(out[i]), .en(1'b1), .*);         
      end   
   endgenerate

   // Logic for valid_out
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
         for (int i=0; i < LATENCY; i++) valid_delay_r[i] = '0;
      end
      else begin
         valid_delay_r[0] <= valid_in;   
         for (int i=1; i < LATENCY; i++) valid_delay_r[i] <= valid_delay_r[i-1];
      end      
   end

   assign valid_out = valid_delay_r[LATENCY-1];
      
endmodule



// Module: replicated_pipeline_reset_tree
// Description: This module also replicates the polynomial pipes, but uses a
// register tree to reduce the reset fanout.
//
// NOTE: The reset tree is hardcoded for NUM_REPLICATIONS=8.

module replicated_pipeline_reset_tree
   #(parameter int WIDTH=8,
     parameter int NUM_REPLICATIONS=8)
   (
    input logic              clk,
    input logic              rst,
    input logic [WIDTH-1:0]  in[NUM_REPLICATIONS],
    input logic              valid_in,
    output logic [4*WIDTH-1:0] out[NUM_REPLICATIONS],
    output logic             valid_out
    );

   localparam int            LATENCY=4;
   logic [0:LATENCY-1]       valid_delay_r;

   // Reset tree registers. The dont_merge is needed to avoid synthesis from
   // merging all the registers at each level.
   (* dont_merge *) logic        rst_l0_r;
   (* dont_merge *) logic [0:1]  rst_l1_r;
   (* dont_merge *) logic [0:3]  rst_l2_r;
   (* dont_merge *) logic [0:7]  rst_l3_r;

   // Create the register tree.
   always_ff @(posedge clk) begin
      rst_l0_r <= rst;
      for (int i=0; i < 2; i++) rst_l1_r[i] <= rst_l0_r;
      for (int i=0; i < 4; i++) rst_l2_r[i] <= rst_l1_r[i/2];
      for (int i=0; i < 8; i++) rst_l3_r[i] <= rst_l2_r[i/2];
   end
   
   // Quartus Prime requires the genvar outside the loop. Prime Pro does not.
   genvar i;
   generate
      for (i=0; i < NUM_REPLICATIONS; i++) begin : l_pipelines
         // Here, we connect the reset of each replication to a leaf of the
         // register tree.
         polynomial_pipe #(.WIDTH(WIDTH)) pipe (.rst(rst_l3_r[i]), .x(in[i]), .out(out[i]), .en(1'b1), .*);      
      end   
   endgenerate

   // IMPORTANT: for the valid_out logic, the reset can't have any latency, so
   // it can't use the register tree. If the register tree was used here, the
   // circuit might continue to output valid_out for a few cycles, even after
   // the reset was asserted.
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
         for (int i=0; i < LATENCY; i++) valid_delay_r[i] = '0;
      end
      else begin
         valid_delay_r[0] <= valid_in;   
         for (int i=1; i < LATENCY; i++) valid_delay_r[i] <= valid_delay_r[i-1];
      end      
   end

   assign valid_out = valid_delay_r[LATENCY-1];
      
endmodule


// Module: replicated_pipeline
// Description: Top-level module for selecting an implementation for synthesis
// or simulation.

module replicated_pipeline
   #(parameter int WIDTH=8,
     parameter int NUM_REPLICATIONS=8)
   (
    input logic              clk,
    input logic              rst,
    input logic [WIDTH-1:0]  in[NUM_REPLICATIONS],
    input logic              valid_in,
    output logic [4*WIDTH-1:0] out[NUM_REPLICATIONS],
    output logic             valid_out
    );

   localparam int            LATENCY=4;
  
   replicated_pipeline_full_reset #(.WIDTH(WIDTH), .NUM_REPLICATIONS(NUM_REPLICATIONS)) top (.*);
   //replicated_pipeline_reset_tree #(.WIDTH(WIDTH), .NUM_REPLICATIONS(NUM_REPLICATIONS)) top (.*);
   
endmodule
