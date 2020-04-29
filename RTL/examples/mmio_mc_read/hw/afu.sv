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

   // 4 user registers (memory mapped to address h0020, 0022, 0024, 0026)
   logic [63:0]  user_reg;

   logic 	 bram_wr_en;
   logic [8:0] 	 bram_wr_addr;
   logic [8:0] 	 bram_rd_addr;
   logic [63:0]  bram_rd_data;
   logic [15:0]  offset_addr;
   logic [15:0]  addr_delayed;
      
   // Create a memory-mapped block RAM with 512 words (2^9) and 64-bit words.
   // Address 0 of the BRAM corresponds to MMIO address h0030, address 1 is 0032, etc.
   bram #(
	  .data_width(64),
	  .addr_width(9)
	  )
   mmio_bram (
	      .clk(clk),
	      .wr_en(bram_wr_en),
	      .wr_addr(bram_wr_addr),
	      .wr_data(rx.c0.data[63:0]),
	      .rd_addr(bram_rd_addr),
	      .rd_data(bram_rd_data)
	      );
   
   always_comb
     begin
        offset_addr = mmio_hdr.address - 16'h0030;    
	bram_wr_addr = offset_addr[9:1];

	if (rx.c0.mmioWrValid && (mmio_hdr.address >= 16'h0030 && mmio_hdr.address < 16'h0230))
	  bram_wr_en = 1;
	else
	  bram_wr_en = 0;	
     end
   
   
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

	     // Register the read address input to create one extra cycle of delay.
	     // This isn't necessary, but is done in this example to make illustrate
	     // how to handle multi-cycle reads. When combined with the block RAM's
	     // 1-cycle latency, and the registered output, each read takes 3 cycles.     
	     bram_rd_addr <= offset_addr[9:1];
	     	     
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

   // Delay the transaction ID by the latency of the block RAM read.
   delay 
     #(
       .cycles(3),
       .width(9)
       )
   delay_tid 
     (
      .*,
      .data_in(mmio_hdr.tid),
      .data_out(tx.c2.hdr.tid)	      
      );

   // Delay the read response by the latency of the block RAM read.
   delay 
     #(
       .cycles(3),
       .width(1)	   
       )
   delay_valid 
     (
      .*,
      .data_in(rx.c0.mmioRdValid),
      .data_out(tx.c2.mmioRdValid)	      
      );

   logic [63:0] reg_rd_data, reg_rd_data_delayed;
      
   // Delay the register read data by the latency of the block RAM read.
   delay 
     #(
       .cycles(3),
       .width(64)	   
       )
   delay_reg_data 
     (
      .*,
      .data_in(reg_rd_data),
      .data_out(reg_rd_data_delayed)	      
      );
      
   // Delay the read address by the latency of the block RAM read.
   delay 
     #(
       .cycles(3),
       .width(16)	   
       )
   delay_addr 
     (
      .*,
      .data_in(mmio_hdr.address),
      .data_out(addr_delayed)	      
      );
   
   // Choose either the delayed register data or the block RAM data based
   // on the delayed address.
   always_comb 
     begin
	if (addr_delayed < 16'h0030) begin
	   tx.c2.data = reg_rd_data_delayed;
	end
	else begin
	   tx.c2.data = bram_rd_data;	   
	end;
     end 
   
   // ============================================================= 		    
   // MMIO Register read code
   // Unlike the previous example, in this situation we do not use
   // an always_ff block because we explicitly do not want registers
   // for these assignments. Instead, we want to define signals that
   // get delayed by the latency of the block RAM so that all reads
   // (registers and block RAM) take the same time.
   // ============================================================= 		    
   always_comb
     begin
	// Clear the status registers in the Tx port that aren't used by MMIO.
        tx.c1.hdr    = '0;
        tx.c1.valid  = '0;
        tx.c0.hdr    = '0;
        tx.c0.valid  = '0;
        
	// If there is a read request from the processor, handle that request.
        if (rx.c0.mmioRdValid == 1'b1)
          begin
             
	     // Check the requested read address of the read request and provide the data 
	     // from the resource mapped to that address.
             case (mmio_hdr.address)
	       
	       // =============================================================
	       // IMPORTANT: Every AFU must provide the following control status registers 
	       // mapped to these specific addresses.
	       // =============================================================   
	       
               // AFU header
               16'h0000: reg_rd_data = {
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
               16'h0002: reg_rd_data = afu_id[63:0];
	       
               // AFU_ID_H
               16'h0004: reg_rd_data = afu_id[127:64];
	       
               // DFH_RSVD0 and DFH_RSVD1
               16'h0006: reg_rd_data = 64'h0;
               16'h0008: reg_rd_data = 64'h0;
	       
	       // =============================================================   
		    // Define user memory-mapped resources here
	       // =============================================================   
	       
               // Provide the 64-bit data from the user register mapped to h0020.
               16'h0020: reg_rd_data = user_reg;
	       
	       // If the processor requests an register address that is unused, return 0.
               default:  reg_rd_data = 64'h0;
             endcase
          end
     end
endmodule
