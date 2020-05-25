// Copyright (c) 2020 University of Florida
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Greg Stitt
// University of Florida

// Module Name:  afu.sv
// Project:      mmio_mc_read
// Description:  Implements an AFU with multiple memory-mapped registers, and a memory-
//               mapped block RAM. The example expands on the mmio_ccip example to
//               demonstrate how to handle MMIO reads across multiple cycles, while also
//               demonstrating suggested design practices to make the code parameterized.
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

   // =============================================================
   // Constants for the memory-mapped registers, aka control/status registers (CSRs)
   //
   // NUM_CSR: The number of CSRs. This can be changed and the code will adapt.
   // CSR_BASE_MMIO_ADDR: MMIO address where the first CSR is mapped
   // CSR_UPPER_MMIO_ADDR: MMIO address of the last CSR
   // CSR_DATA_WIDTH: Data width of the CSRs (in bits)
   // ============================================================= 
   localparam int NUM_CSR = 16; 
   localparam [15:0] CSR_BASE_MMIO_ADDR = 16'h0020;
   localparam [15:0] CSR_UPPER_MMIO_ADDR = CSR_BASE_MMIO_ADDR + NUM_CSR*2 - 2;
   localparam int CSR_DATA_WIDTH = 64;
   
   // =============================================================
   // Constants for the memory-mapped block RAM (BRAM)
   //
   // BRAM_RD_LATENCY: the read latency of the BRAM. NOTE: this constant cannot
   //                  be changed without changing the timing of the block RAM.
   //                  This is solely a named constant to avoid having hardcoded
   //                  literals throughout the code.
   // BRAM_WORDS: Number of words in the block RAM.
   // BRAM_ADDR_WIDTH: The address width of the block RAM.
   // BRAM_DATA_WIDTH: The data width of each block RAM word.
   // BRAM_BASE_MMIO_ADDR: MMIO address where the first BRAM word is mapped.
   // BRAM_UPPER_MMIO_ADDR: MMIO address of the last BRAM word.
   // ============================================================= 
   localparam int BRAM_RD_LATENCY = 3;
   localparam int BRAM_WORDS = 512;
   localparam int BRAM_ADDR_WIDTH = $clog2(BRAM_WORDS);
   localparam int BRAM_DATA_WIDTH = 64;
   localparam [15:0] BRAM_BASE_MMIO_ADDR = 16'h0080;
   localparam [15:0] BRAM_UPPER_MMIO_ADDR = BRAM_BASE_MMIO_ADDR + BRAM_WORDS*2 - 2;

   // AFU ID
   localparam [127:0] AFU_ID = `AFU_ACCEL_UUID;
   
   // Make sure the parameter configuration doesn't result in the CSRs 
   // conflicting with the BRAM address space.
   initial begin
      if (NUM_CSR > (BRAM_BASE_MMIO_ADDR-CSR_BASE_MMIO_ADDR)/2)
	$error("CSR addresses conflict with BRAM addresses");
   end
           
   // Get the MMIO header by casting the overloaded rx.c0.hdr port.   
   t_ccip_c0_ReqMmioHdr mmio_hdr;
   assign mmio_hdr = t_ccip_c0_ReqMmioHdr'(rx.c0.hdr);
   
   // Declare control/status registers.
   logic [CSR_DATA_WIDTH-1:0] csr[NUM_CSR];

   // The index into the CSRs based on the current address.
   // $clog2 is a very useful function for computing the number of bits based on an
   // amount. For example, if we have 3 status registers, we would need ceiling(log2(3)) = 2
   // bits to address all the registers.
   localparam CSR_WIDTH = $clog2(NUM_CSR);
   logic [CSR_WIDTH-1:0] csr_index_rd, csr_index_wr;

   // Block RAM signals.
   // Similarly, $clog2 is used here to calculated the width of the address lines
   // based on the number of words.
   logic 		       bram_wr_en;
   logic [BRAM_ADDR_WIDTH-1:0] bram_wr_addr, bram_rd_addr, bram_addr;
   logic [BRAM_DATA_WIDTH-1:0] 	  bram_rd_data;

   // MMIO address after applying the offset of base MMIO address of the BRAM. 
   logic [15:0] 		  offset_addr;

   // Variables used for delaying various signals.
   logic [15:0] 		  addr_delayed;
   logic 			  mmioRdValid_delayed;
   
   // Instantiate a block RAM with 2^BRAM_ADDR_WIDTH words, where each word is
   // BRAM_DATA_WIDTH bits. Internally, this block RAM registers the output
   // which leads to a 2-cycle read latency. However, the address is also
   // registered below, which results in a 3-cycle read latency. This delay
   // is largely synthetic for this example to demonstrate multi-cycle reads,
   // although registered a block RAM output is common.
   //
   // Address 0 of the BRAM corresponds to MMIO address BRAM_BASE_MMIO_ADDR.
   bram #(
	  .DATA_WIDTH(BRAM_DATA_WIDTH),
	  .ADDR_WIDTH(BRAM_ADDR_WIDTH)
	  )
   mmio_bram (
	      .clk(clk),
	      .wr_en(bram_wr_en),
	      .wr_addr(bram_wr_addr),
	      .wr_data(rx.c0.data[BRAM_DATA_WIDTH-1:0]),
	      .rd_addr(bram_rd_addr),
	      .rd_data(bram_rd_data)
	      );

   // Misc. combinatonal logic for addressing and control.
   always_comb begin
      
      logic [$size(mmio_hdr.address)-1:0] csr_offset_addr_wr, csr_offset_addr_rd;
      logic [$size(mmio_hdr.address)-1:0] bram_offset_addr;

      // Compute the index of the CSR based on the mmio address.
      // The divide by two (shift right) accounts for the fact that each MMIO is
      // 32-bit word addressable, but registers are 64 bits.
      // e.g. CSR_BASE_MMIO_ADDR+2 maps to csr_index 1.
      // e.g. CSR_BASE_MMIO_ADDR+4 maps to csr_index 2
      // There are two different indexes used here because the write
      // index is not delayed, but the read index has to be delayed
      // to align with the output of the block RAM read.
      csr_offset_addr_wr = mmio_hdr.address - CSR_BASE_MMIO_ADDR;
      csr_offset_addr_rd = addr_delayed - CSR_BASE_MMIO_ADDR;

      // I would prefer to just use $size(csr_index_wr) but Quartus reports
      // an incorrect watning that csr_index_wr is used before assigned.
      csr_index_wr = csr_offset_addr_wr[CSR_WIDTH:1];
      csr_index_rd = csr_offset_addr_rd[CSR_WIDTH:1];
      
      // Subtract the BRAM address offset from the MMIO address to align the
      // MMIO addresses with the BRAM words. The divide by two (shift right) accounts for
      // MMIO being 32-bit word addressable and the block RAM being 64-bit word
      // addressable.
      // e.g. MMIO BRAM_BASE_MMIO_ADDR = BRAM address 0
      // e.g. MMIO BRAM_BAS_MMIO_ADDR+2 = BRAM address 1       
      bram_offset_addr = mmio_hdr.address - BRAM_BASE_MMIO_ADDR;	
      bram_addr = bram_offset_addr[BRAM_ADDR_WIDTH:1];

      // Define the bram write address.
      bram_wr_addr = bram_addr;

      // Write to the block RAM when there is a MMIO write request and the address falls
      // within the range of the BRAM
      if (rx.c0.mmioWrValid && (mmio_hdr.address >= BRAM_BASE_MMIO_ADDR && mmio_hdr.address <= BRAM_UPPER_MMIO_ADDR ))
	bram_wr_en = 1'b1;
      else
	bram_wr_en = 1'b0;	
   end    

   // Sequential logic to create all registers.
   always_ff @(posedge clk or posedge rst) begin      
      if (rst) begin 
	 // Asynchronous reset for the CSRs.
	 for (int i=0; i < NUM_CSR; i++) begin
	    csr[i] <= '0;
	 end		       
      end
      else begin
	 // Register the read address input to create one extra cycle of delay.
	 // This isn't necessary, but is done in this example to illustrate
	 // how to handle multi-cycle reads. When combined with the block RAM's
	 // 1-cycle latency, and the registered output, each read takes 3 cycles.     
	 bram_rd_addr <= bram_addr;
	 
         // Check to see if there is a valid write being received from the processor.	    
         if (rx.c0.mmioWrValid) begin
	    // Verify the address is within the range of CSR addresses.
	    // If so, store into the corresponding register.
	    // NOTE: In realistic use cases, many of the CSRs will only be writeable by
	    // the AFU itself. For example, if a hardware exception occurs during execution,
	    // the AFU can put an error code into a CSR that software can read.
	    // In general, all CSRs can be read by software, but only some can be written
	    // by software. This example allows software writes to all CSRs solely for
	    // MMIO testing purposes.
	    if (mmio_hdr.address >= CSR_BASE_MMIO_ADDR && mmio_hdr.address <= CSR_UPPER_MMIO_ADDR) begin
	       csr[csr_index_wr] <= rx.c0.data[CSR_DATA_WIDTH-1:0];
	    end		 		  
         end
      end
   end
   
   // ============================================================= 		    
   // MMIO CSR read code
   // Unlike the previous examples, in this situation we do not use
   // an always_ff block because we explicitly do not want registers
   // for these assignments. See the schematic in the corresponding
   // set of slides. 
   // ============================================================= 		    
   always_comb begin
      // Clear the status flags in the Tx port that aren't used by MMIO.
      tx.c1.hdr    = '0;
      tx.c1.valid  = '0;
      tx.c0.hdr    = '0;
      tx.c0.valid  = '0;
      tx.c2.data   = '0;       
      
      // Check the requested read address of the read request and provide the data 
      // from the resource mapped to that address. Note that this address is the
      // delayed address because we had to wait multiple cycles for the block RAM
      // to respond.
      case (addr_delayed)
	
	// Provide the required AFU header CSRs	       	       
        // AFU header
        16'h0000: tx.c2.data = {
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
        16'h0002: tx.c2.data = AFU_ID[63:0];
	
        // AFU_ID_H
        16'h0004: tx.c2.data = AFU_ID[127:64];
	
        // DFH_RSVD0 and DFH_RSVD1
        16'h0006: tx.c2.data = 64'h0;
        16'h0008: tx.c2.data = 64'h0;
	
	// =============================================================   
	// Define user CSRs here
	// =============================================================   
      	
        default:
	  // Check to see if the delayed address falls withing the CSR or BRAM range.
	  if (addr_delayed >= CSR_BASE_MMIO_ADDR && addr_delayed <= CSR_UPPER_MMIO_ADDR)
	    tx.c2.data = csr[csr_index_rd];
	  else if (addr_delayed >= BRAM_BASE_MMIO_ADDR && addr_delayed <= BRAM_UPPER_MMIO_ADDR)
	    tx.c2.data = bram_rd_data;	       
      endcase

   end // always_comb

   // =============================================================   
   // Delays to wait for the multi-cycle block RAM reads.
   // =============================================================   
   
   // Delay the transaction ID by the latency of the block RAM read.
   // This demonstrates the use of $size to get the number of bits in a variable.
   // $size is useful because it conveys the purpose, as opposed to just providing
   // a literal. It is also useful when the corresponding variable may change sizes
   // in different situations.
   delay 
     #(
       .CYCLES(BRAM_RD_LATENCY),
       .WIDTH($size(mmio_hdr.tid))
       )
   delay_tid 
     (
      .*,
      .en(1'b1),
      .data_in(mmio_hdr.tid),
      .data_out(tx.c2.hdr.tid)	      
      );

   // Delay the read response by the latency of the block RAM read.
   delay 
     #(
       .CYCLES(BRAM_RD_LATENCY),
       .WIDTH($bits(rx.c0.mmioRdValid))	   
       )
   delay_valid 
     (
      .*,
      .en(1'b1),
      .data_in(rx.c0.mmioRdValid),
      .data_out(mmioRdValid_delayed)	      
      );

   assign tx.c2.mmioRdValid = mmioRdValid_delayed;
   
   // Delay the read address by the latency of the block RAM read.
   delay 
     #(
       .CYCLES(BRAM_RD_LATENCY),       
       .WIDTH($size(mmio_hdr.address))	   
       )
   delay_addr 
     (
      .*,
      .en(1'b1),
      .data_in(mmio_hdr.address),
      .data_out(addr_delayed)	      
      );
   
endmodule
