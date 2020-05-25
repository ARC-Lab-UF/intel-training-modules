// Greg Stitt
// University of Florida

// Module Name:  memory_map.sv
// Project:      mmio_fib
// Description:  Implements the memory mapping for the fib I/O
//               Software provides two inputs (n and go), where
//               n specifies which Fibonacci number to calculate
//               and go tells the AFU to start.
//
//               The AFU produces two outputs (result and done),
//               where result is the corresponding Fibonacci number
//               and the assertion of done signifies the completion.
//
//               n      : h0020
//               go     : h0022
//               result : h0024
//               done   : h0026


`include "platform_if.vh"
`include "afu_json_info.vh"

module memory_map
  (
   input  clk,
   input  rst, 

   // CCI-P signals
   input  t_if_ccip_Rx rx,
   output t_if_ccip_Tx tx,

   // Memory-mapped signals that communicate with fib module
   output [31:0] n,
   output go,
   input [31:0] result,
   input done
   );

   localparam [127:0] afu_id = `AFU_ACCEL_UUID;

   // Fib input registers (memory mapped to address h0020, h0022).
   logic go_r;
   logic [31:0] n_r;

   // Connect internal registers to ports.
   assign n = n_r;
   assign go = go_r;
 
   // Get mmio request header.
   t_ccip_c0_ReqMmioHdr mmio_hdr;
   assign mmio_hdr = t_ccip_c0_ReqMmioHdr'(rx.c0.hdr);
   
   // =============================================================//   
   // MMIO write code
   // =============================================================// 		    
   always_ff @(posedge clk or posedge rst)
     begin 
        if (rst)
          begin
	     go_r <= '0;
	     n_r  <= '0;	    
          end
        else 
          begin
	     // Clear go every cycle to ensure an MMIO write only
	     // creates a 1-cycle high pulse. This saves a PCIe
	     // transfer to clear the go signal.
	     go_r <= 1'b0;
	     	     
             if (rx.c0.mmioWrValid)
               begin
                  case (mmio_hdr.address)
                    16'h0020: go_r <= rx.c0.data[0];
		    16'h0022: n_r  <= rx.c0.data[31:0];
                  endcase
               end
          end
     end

   // =============================================================    
   // MMIO read code
   // =============================================================	    
   always_ff @(posedge clk or posedge rst) 
     begin
        if (rst)
          begin
             tx.c1.hdr 	       <= '0;
             tx.c1.valid       <= '0;
             tx.c0.hdr 	       <= '0;
             tx.c0.valid       <= '0;
             tx.c2.hdr 	       <= '0;
             tx.c2.mmioRdValid <= '0;
          end
        else
          begin
             tx.c2.mmioRdValid <= 1'b0;

             if (rx.c0.mmioRdValid)
               begin
                  tx.c2.hdr.tid     <= mmio_hdr.tid;
                  tx.c2.mmioRdValid <= 1'b1;

		  // By default, set all data bits to 0 to save code below
		  tx.c2.data <= '0;
		  
                  case (mmio_hdr.address)
		    
		    // =============================================================
		    // IMPORTANT: Every AFU must provide the following control status registers 
		    // mapped to these specific addresses.
		    // =============================================================   
		    
                    // AFU header
                    16'h0000: tx.c2.data <= {
					     4'b0001, // Feature type = AFU
					     8'b0,    // reserved
					     4'b0,    // afu minor revision = 0
					     7'b0,    // reserved
					     1'b1,    // end of DFH list = 1
					     24'b0,   // next DFH offset = 0
					     4'b0,    // afu major revision = 0
					     12'b0    // feature ID = 0
					     };

                    // AFU_ID_L
                    16'h0002: tx.c2.data <= afu_id[63:0];

                    // AFU_ID_H
                    16'h0004: tx.c2.data <= afu_id[127:64];

                    // DFH_RSVD0 and DFH_RSVD1
                    16'h0006: tx.c2.data <= 64'h0;
                    16'h0008: tx.c2.data <= 64'h0;
		    
		    // =============================================================   
		    // Define user memory-mapped resources here
		    // =============================================================   

		    // Read from the fib input registers. Although this is not
		    // necessary, it provides a mechanism for software to verify
		    // that MMIO transfers succeeded. However, reading from go
		    // always return 0 since it is only ever asserted for 1 cycle.
                    16'h0020: tx.c2.data[0] <= go_r;
		    16'h0022: tx.c2.data[$size(n_r)-1:0] <= n_r;

		    // Read from the fib outputs.
		    16'h0024: tx.c2.data <= result;
		    16'h0026: tx.c2.data <= done;

		    // If the processor requests an address that is unused, return 0.
                    default:  tx.c2.data <= 64'h0;
                  endcase
               end
          end
     end
endmodule

   
