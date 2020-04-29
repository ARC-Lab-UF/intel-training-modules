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
// Project:      mmio_mc_read
// Description:  Implements an AFU with multiple memory-mapped registers, and a a memory-
//               mapped block RAM.
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

   // Local constants
   localparam int NUM_CSR = 4;
   localparam int CSR_BASE_MMIO_ADDR = 16'h0020;
   localparam int CSR_DATA_WIDTH = 64;

   localparam int BRAM_RD_LATENCY = 3;
   localparam int BRAM_WORDS = 512;
   localparam int BRAM_ADDR_WIDTH = $clog2(BRAM_WORDS);
   localparam int BRAM_DATA_WIDTH = 64;
   localparam int BRAM_BASE_MMIO_ADDR = 16'h0030;
   localparam int BRAM_UPPER_MMIO_ADDR = BRAM_BASE_MMIO_ADDR + BRAM_WORDS*2;

   // Make sure the configuration does result in the CSRs conflicting with the
   // BRAM address space.
   if (NUM_CSR >= (BRAM_BASE_MMIO_ADDR-CSR_BASE_MMIO_ADDR)/2) begin
      $error("CSR addresses conflit with BRAM addresses");
   end       
   
   // The AFU must respond with its AFU ID in response to MMIO reads of the CCI-P device feature 
   // header (DFH).  The AFU ID is a unique ID for a given program. Here we generated one with 
   // the "uuidgen" program and stored it in the AFU's JSON file. ASE and synthesis setup scripts
   // automatically invoke the OPAE afu_json_mgr script to extract the UUID into a constant 
   // within afu_json_info.vh.
   logic [127:0] afu_id = `AFU_ACCEL_UUID;

   // 4 user registers (memory mapped to addresses h0020, 0022, 0024, 0026)
   logic [CSR_DATA_WIDTH-1:0] user_reg;

   logic 	 bram_wr_en;
   logic [$clog2(BRAM_WORDS)-1:0] bram_wr_addr, bram_rd_addr;
   logic [BRAM_DATA_WIDTH-1:0]  bram_rd_data;
   logic [15:0]  offset_addr;
   logic [15:0]  addr_delayed;
      
   // Create a memory-mapped block RAM with 512 words (2^9) and 64-bit words.
   // Address 0 of the BRAM corresponds to MMIO address h0030, address 1 is 0032, etc.
   bram #(
	  .data_width(BRAM_DATA_WIDTH),
	  .addr_width(BRAM_ADDR_WIDTH)
	  )
   mmio_bram (
	      .clk(clk),
	      .wr_en(bram_wr_en),
	      .wr_addr(bram_wr_addr),
	      .wr_data(rx.c0.data[BRAM_DATA_WIDTH-1:0]),
	      .rd_addr(bram_rd_addr),
	      .rd_data(bram_rd_data)
	      );

   // Combinational logic to compute the corresponding bram_wr_addr and bram_wr_en
   always_comb
     begin
	// Subtract the BRAM address offset from the MMIO address to align the
	// MMIO addresses with the BRAM words.
	// e.g. MMIO address h0030 = BRAM address 0
        offset_addr = mmio_hdr.address - BRAM_BASE_MMIO_ADDR; 

	// Divide the offset address by two to account for the BRAM being
	// 64-bit word addressable and MMIO using 32-bit word addressable
	// e.g. MMIO address h0032 => offest_addr 2 => bram_wr_addr 1 
	bram_wr_addr = offset_addr[BRAM_ADDR_WIDTH:1];

	// Write to the block RAM when there is a MMIO write request and the address falls
	// within the range of the BRAM
	if (rx.c0.mmioWrValid && (mmio_hdr.address >= BRAM_BASE_MMIO_ADDR && mmio_hdr.address <= BRAM_UPPER_MMIO_ADDR ))
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
	     bram_rd_addr <= offset_addr[BRAM_ADDR_WIDTH:1];
	     	     
             // Check to see if there is a valid write being received from the processor.
             if (rx.c0.mmioWrValid == 1)
               begin
		  logic [15:0] stuff;
		  
		  
		  // Check the address of the write request. If it maches the address of the
		  // memory-mapped register (h0020), then write the received data on channel c0 
		  // to the register.
                  case (mmio_hdr.address)
                    16'h0020: user_reg <= rx.c0.data[CSR_DATA_WIDTH-1:0];
                  endcase
               end
          end
     end

   // Delay the transaction ID by the latency of the block RAM read.
   delay 
     #(
       .cycles(BRAM_RD_LATENCY),
       .width($size(mmio_hdr.tid))
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
       .cycles(BRAM_RD_LATENCY),
       .width($size(rx.c0.mmioRdValid))	   
       )
   delay_valid 
     (
      .*,
      .data_in(rx.c0.mmioRdValid),
      .data_out(tx.c2.mmioRdValid)	      
      );

   logic [CSR_DATA_WIDTH-1:0] reg_rd_data, reg_rd_data_delayed;
      
   // Delay the register read data by the latency of the block RAM read.
   delay 
     #(
       .cycles(BRAM_RD_LATENCY),
       .width($size(reg_rd_data))	   
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
       .cycles(BRAM_RD_LATENCY),
       .width($size(mmio_hdr.address))	   
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
	if (addr_delayed < BRAM_BASE_MMIO_ADDR) begin
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
