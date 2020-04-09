// ***************************************************************************
// Copyright (c) 2013-2018, Intel Corporation
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
// * Neither the name of Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// ***************************************************************************

// Module Name:  afu.sv
// Project:      ccip_mmio
// Description:  Implements an AFU with a single memory-mapped user register to demonstrate
//               memory-mapped I/O (MMIO) using the Core Cache Interface Protocol (CCI-P).
//
//               This module provides a simplified AFU interface since not all the functionality 
//               of the ccip_std_afu interface is required. Specifically, the afu module provides
//               a single clock, simplified port names, and all I/O has already been registered,
//               which is required by any AFU.
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
   // Rx receives data from the host processor. Tx sends data to the host processor.
   input  t_if_ccip_Rx rx,
   output t_if_ccip_Tx tx
   );

   // The AFU must respond with its AFU ID in response to MMIO reads of the CCI-P device feature 
   // header (DFH).  The AFU ID is a unique ID for a given program. Here we generated one with 
   // the "uuidgen" program and stored it in the AFU's JSON file. ASE and synthesis setup scripts
   // automatically invoke the OPAE afu_json_mgr script to extract the UUID into a constant 
   // within afu_json_info.vh.
   logic [127:0] afu_id = `AFU_ACCEL_UUID;

   // User register (memory mapped to address h0020) to test MMIO over CCI-P.
   logic [63:0]  user_reg;
   
   // The Rx c0 header is normally used for responses to reads from the host processor's memory.
   // For MMIO responses (i.e. when c0 mmmioRdValid or mmioWrValid is asserted), we need to 
   // cast the c0 header into a ReqMmmioHdr. Basically, these same header bits in Rx c0 are used 
   // for different purposes depending on the response type.
   t_ccip_c0_ReqMmioHdr mmio_hdr;
   assign mmio_hdr = t_ccip_c0_ReqMmioHdr'(rx.c0.hdr);

   // =============================================================//   
   // MMIO write code
   // =============================================================// 		    
   always_ff @(posedge clk or posedge rst)
     begin 
        if (rst)
          begin 
	     // Asnchronous reset for the memory-mapped register.
	     user_reg <= '0;
          end
        else
          begin
             // Check to see if there is a valid write being received from the processor.
             if (rx.c0.mmioWrValid == 1)
               begin
		  // Check the address of the write request. If it maches the address of the
		  // memory-mapped register (h0020), then write the received data on channel c0 
		  // to the register.
                  case (mmio_hdr.address)
                    16'h0020: user_reg <= rx.c0.data[63:0];
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
	     // Reset the status registers in the Tx port.
             tx.c1.hdr 	       <= '0;
             tx.c1.valid       <= '0;
             tx.c0.hdr 	       <= '0;
             tx.c0.valid       <= '0;
             tx.c2.hdr 	       <= '0;
             tx.c2.mmioRdValid <= '0;
          end
        else
          begin
             // Clear read response flag every cycle in case there was a response last cycle.
             tx.c2.mmioRdValid <= 0;

             // If there is a read request from the processor, handle that request.
             if (rx.c0.mmioRdValid == 1'b1)
               begin
                  // Copy TID, which the host needs to map the response to the request.
                  tx.c2.hdr.tid <= mmio_hdr.tid;

                  // Inform the processor that the AFU is responding.
                  tx.c2.mmioRdValid <= 1;

		  // Check the requested read address of the read request and provide the data 
		  // from the resource mapped to that address.
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
		    
                    // Provide the 64-bit data from the user register mapped to h0020.
                    16'h0020: tx.c2.data <= user_reg;

		    // If the processor requests an address that is unused, return 0.
                    default:  tx.c2.data <= 64'h0;
                  endcase
               end
          end
     end
endmodule
