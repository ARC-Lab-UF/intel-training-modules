// Greg Stitt
// Kevin Ferreira
// University of Florida
//
// Module Name:  afu.sv
// Project:      mmio_add
// Description:  Implements an AFU that adds two numbers from memory-mapped registers, and
//               stores the result in a third memory-mapped reigster.
//
//               This code assumes the reader has studied the ccio_mmio example provided
//               along with this exercise.
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

   // User registers (memory mapped to address h0020, h0022, and h0024)
   logic [63:0]  add_in0_r, add_in1_r, add_out_r;
   
   // Get mmio request header.
   t_ccip_c0_ReqMmioHdr mmio_hdr;
   assign mmio_hdr = t_ccip_c0_ReqMmioHdr'(rx.c0.hdr);

   // =============================================================//   
   // Create adder with registered output.
   // NOTE: This could be combined with the MMIO write always block
   // =============================================================// 
   
   always_ff @(posedge clk or posedge rst)
     begin
	if (rst)
	  begin
	     add_out_r <= '0;	     
	  end
	else
	  begin
	     add_out_r <= add_in0_r + add_in1_r;	     
	  end	  
     end 
   
   // =============================================================//   
   // MMIO write code
   // =============================================================// 		    
   always_ff @(posedge clk or posedge rst)
     begin 
        if (rst)
          begin 
	     add_in0_r <= '0;
	     add_in1_r <= '0;	     
          end
        else
          begin
             if (rx.c0.mmioWrValid)
               begin
                  case (mmio_hdr.address)
		    // Only allow MMIO writes to the adder inputs
		    // to avoid multiple drivers on the adder's
		    // output register.		    
                    16'h0020: add_in0_r <= rx.c0.data[63:0];
		    16'h0022: add_in1_r <= rx.c0.data[63:0];
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

		    // Reading from the adder inputs enables software to ensure that
		    // transfers were successul.
                    16'h0020: tx.c2.data <= add_in0_r;
		    16'h0022: tx.c2.data <= add_in1_r;

		    // Read from the adder's output register.
		    16'h0024: tx.c2.data <= add_out_r;

		    // If the processor requests an address that is unused, return 0.
                    default:  tx.c2.data <= 64'h0;
                  endcase
               end
          end
     end
endmodule
