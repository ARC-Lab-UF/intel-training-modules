// Module Name:  afu.sv
// Project:      mmio_add
// Description:  Implements an AFU that adds two numbers from memory-mapped registers, and
//               stores the result in a third memory-mapped reigster.
//
//               This code assumes the reader has studied the ccio_mmio example provided
//               along with this exercise.
//
//               See TODO comments to determine what to complete for the exercise.
//
// For more information on CCI-P, see the Intel Acceleration Stack for Intel Xeon CPU with 
// FPGAs Core Cache Interface (CCI-P) Reference Manual

`include "platform_if.vh"
`include "afu_json_info.vh"

module afu
  (
   input  clk,
   input  rst, 

   // CCI-P signals
   input  t_if_ccip_Rx rx,
   output t_if_ccip_Tx tx
   );

   localparam [127:0] afu_id = `AFU_ACCEL_UUID;

   // Get mmio request header.
   t_ccip_c0_ReqMmioHdr mmio_hdr;
   assign mmio_hdr = t_ccip_c0_ReqMmioHdr'(rx.c0.hdr);

   // TODO: Implement adder with two registered inputs and a registered
   // output. Make all the registers accessible over MMIO.

   
   // =============================================================//   
   // MMIO write code
   // =============================================================// 		    
   always_ff @(posedge clk or posedge rst)
     begin 
        if (rst)
          begin 
	    // TODO: Reset the user registers	     
          end
        else
          begin
             if (rx.c0.mmioWrValid)
               begin
                  case (mmio_hdr.address)
		    // TODO : Implement writes to each adder input register
		    // IMPORTANT: You must use even addresses needed due to 64-bit transfers
		    // from software. Odd addresses can be used for 32-bit transfers but
		    // are not provided by the C++ API provided in the exercise.
		    // Each address corresponds to a 32-bit word.
		    
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
                  tx.c2.hdr.tid <= mmio_hdr.tid;
                  tx.c2.mmioRdValid <= 1'b1;

                  case (mmio_hdr.address)
		    
		    // =============================================================
		    // IMPORTANT: Every AFU must provide the following control status registers 
		    // mapped to these specific addresses.
		    // DO NOT CHANGE.
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
		    // TODO: Define user memory-mapped resources here
		    // =============================================================   

		    

		    // If the processor requests an address that is unused, return 0.
                    default:  tx.c2.data <= 64'h0;
                  endcase
               end
          end
     end
endmodule
