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
// Project:      simple pipeline
// Description:  This AFU implements a simple pipeline that streams 32-bit
//               floats from an input array, with each cache line
//               providing 16 inputs. The pipeline multiplies the 8 pairs of
//               inputs from each input cache line, and sums all the products
//               to get a 32-bit float result that is written to an output 
//               array. All multiplications and additions use 32-bit floats.
//
//               Since each output is 32 bits, the AFU must generate 16 outputs
//               before writing a cache line to memory (512 bits). The AFU
//               uses output buffering to pack 16 separate 32-bit outputs into
//               a single 512-bit buffer that is then written to memory.
//
//               Although the AFU could be extended to support any number of
//               inputs and/or outputs, software ensures that the number of
//               inputs is a multiple of 16, so the AFU doesn't have to consider
//               the situation of ending without 16 results in the buffer to
//               write to memory (i.e. an incomplete cache line on the final
//               transfer.

//               The AFU uses MMIO to receive the starting read adress, 
//               starting write address, input_size (# of input cache lines), 
//               and a go signal. The AFU asserts a MMIO done signal to tell 
//               software that the DMA that all results have been written to
//               memory.
//
//               This example assumes the user is familiar with the
//               dma_loopback and dma_loop_uclk training modules.

import pipe_pkg::*;

//===================================================================
// Interface Description
// clk  : Clock input
// rst  : Reset input (active high)
// mmio : Memory-mapped I/O interface. See mmio_if.vh and description above.
// dma  : DMA interface. See dma_if.vh and description above.
//===================================================================

`include "cci_mpf_if.vh"

module afu 
  (
   input clk,
   input rst,
	 mmio_if.user mmio,
	 dma_if.peripheral dma
   );

   localparam int CL_ADDR_WIDTH = $size(t_ccip_clAddr);
   localparam int CL_DATA_WIDTH = $size(t_ccip_clData);
   localparam int INPUT_WIDTH = 32;   
   localparam int RESULT_WIDTH = 32;
   localparam int INPUTS_PER_CL = CL_DATA_WIDTH / INPUT_WIDTH;   // 16
   localparam int RESULTS_PER_CL = CL_DATA_WIDTH / RESULT_WIDTH; // 16
       
   // 512 is the shallowest a block RAM can be in the Arria 10, so there's no 
   // point in making it smaller unless using MLABs instead.
   localparam int FIFO_DEPTH = 512;
            
   // I want to just use dma.count_t, but apparently
   // either SV or Modelsim doesn't support that. Similarly, I can't
   // just do dma.SIZE_WIDTH without getting errors or warnings about
   // "constant expression cannot contain a hierarchical identifier" in
   // some tools. Declaring a function within the interface works just fine in
   // some tools, but in Quartus I get an error about too many ports in the
   // module instantiation.
   typedef logic [CL_ADDR_WIDTH:0] count_t;   
   count_t 	input_size;
   logic 	go;
   logic 	done;

   // Software provides 64-bit virtual byte addresses.
   // Again, this constant would ideally get read from the DMA interface if
   // there was widespread tool support.
   localparam int VIRTUAL_BYTE_ADDR_WIDTH = 64;
   logic [VIRTUAL_BYTE_ADDR_WIDTH-1:0] rd_addr, wr_addr;

   // Instantiate the memory map, which provides the starting read/write
   // 64-bit virtual byte addresses, an input size (in cache lines), and a
   // go signal. It also sends a done signal back to software.
   memory_map
     #(
       .ADDR_WIDTH(VIRTUAL_BYTE_ADDR_WIDTH),
       .SIZE_WIDTH(CL_ADDR_WIDTH+1)
       )
     memory_map (.*);

   // Slice the DMA read data (i.e. cache line) into 16 separate 32-bit inputs.
   logic [INPUT_WIDTH-1:0] pipeline_inputs[INPUTS_PER_CL];
   always_comb begin
      for (int i=0; i < INPUTS_PER_CL; i++) begin
	 pipeline_inputs[i] = dma.rd_data[INPUT_WIDTH*i +: INPUT_WIDTH];
      end      
   end

   logic pipeline_valid_out;
   logic [RESULT_WIDTH-1:0] pipeline_result;

   // Instantiate the pipeline.
   // The pipeline is always enabled due to the use of an absorption FIFO. See
   // comments below.
   // The pipeline has valid inputs everytime data is read from the DMA, and
   // has a valid output when pipeline_valid_out is asserted, with the result
   // showing up on pipeline_result.
   pipeline pipeline (.clk,
		      .rst,
		      .en(1'b1),
		      .valid_in(dma.rd_en),
		      .inputs(pipeline_inputs),
		      .result(pipeline_result),
		      .valid_out(pipeline_valid_out));

   logic 		    fifo_rd_en, fifo_empty, fifo_almost_full;
   logic [RESULT_WIDTH-1:0] fifo_rd_data;
         
   // This FIFO isn't needed, but if removed the pipeline must be stalled 
   // (en = 0) whenever dma.full is 1. Stalling a pipeline requires a large 
   // fan-out on the enable signal, which can reduce clock frequency. Stalls
   // also prevent usage of HyperRegisters on Stratix 10 designs.
   //
   // This absorption FIFO creates the illusion of a stall by stopping the 
   // inputs to the pipeline during a stall and "absorbing" the existing 
   // contents of the pipeline. See the following paper for more details:
   //
   // M. N. Emas, A. Baylis and G. Stitt, "High-Frequency Absorption-FIFO 
   // Pipelining for Stratix 10 HyperFlex," 2018 IEEE 26th Annual International 
   // Symposium on Field-Programmable Custom Computing Machines (FCCM), 
   // Boulder, CO, 2018, pp. 97-100, doi: 10.1109/FCCM.2018.00024.
   fifo 
     #(
       .WIDTH(RESULT_WIDTH),
       .DEPTH(FIFO_DEPTH),
       // This leaves enough space to absorb the entire contents of the
       // pipeline when there is a stall.
       .ALMOST_FULL_COUNT(FIFO_DEPTH-pipe_pkg::PIPE_LATENCY)
       )
   absorption_fifo 
     (
      .clk(clk),
      .rst(rst),
      .rd_en(fifo_rd_en),
      .wr_en(pipeline_valid_out),
      .empty(fifo_empty),
      .full(), // Not used in an absorption FIFO.
      .almost_full(fifo_almost_full),
      .count(),
      .space(),
      .wr_data(pipeline_result),
      .rd_data(fifo_rd_data)
      );

   // Tracks the number of results in the output buffer to know when to
   // write the buffer to memory (when a full cache line is available).
   logic [$clog2(RESULTS_PER_CL):0] result_count_r;

   // Output buffer to assemble a cache line out of 64-bit results.
   logic [CL_DATA_WIDTH-1:0] output_buffer_r;
   
   // The output buffer is full when it contains RESULT_PER_CL results (i.e.,
   // a full cache line) to write to memory and there isn't currently a write
   // to the DMA (which resets result_count_r). The && !dma.wr_en isn't neeeded
   // but can save a cycle every time there is an output written to memory.
   logic output_buffer_full;
   assign output_buffer_full = (result_count_r == RESULTS_PER_CL) && !dma.wr_en;
   
   // Read from the absorption FIFO when there is data in it, and when the 
   // output buffer is not full.     
   assign fifo_rd_en = !fifo_empty && !output_buffer_full;   
   
   // Pack results into a cache line to write to memory.
   always_ff @ (posedge clk or posedge rst) begin     
      if (rst) begin
	 result_count_r <= '0;
      end
      else begin
	 // Every time the DMA writes a cache line, reset the result count.
	 if (dma.wr_en) begin
	    // Must be blocking assignment in case fifo_rd_en is also asserted.
	    result_count_r = '0;
	 end        		 
	 
	 // Whenever something is read from the absorption fifo, shift the 
	 // output buffer to the right and append the data from the FIFO to 
	 // the front of the buffer.
	 // After RESULTS_PER_CL reads from the FIFO, output_buffer_r will 
	 // contain RESULTS_PER_CL complete results, all aligned correctly for
	 //  memory.
	 if (fifo_rd_en) begin
	    output_buffer_r <= {fifo_rd_data, 
				output_buffer_r[CL_DATA_WIDTH-1:RESULT_WIDTH]};

	    // Track the number of results in the output buffer. There is
	    // a full cache line when result_count_r reaches RESULTS_PER_CL.
	    result_count_r ++;
	 end
      end
   end // always_ff @
      
   // Assign the starting addresses from the memory map.
   assign dma.rd_addr = rd_addr;
   assign dma.wr_addr = wr_addr;
   
   // Use the input size (# of input cache lines) specified by software.
   assign dma.rd_size = input_size;

   // For every input cache line, we get 16 32-bit inputs. These inputs produce
   // one 32-bit output. We can store 16 outputs in a cache line, so there is
   // one output cache line for every 16 input cache lines.
   assign dma.wr_size = input_size >> 4;

   // Start both the read and write channels when the MMIO go is received.
   // Note that writes don't actually occur until dma.wr_en is asserted.
   assign dma.rd_go = go;
   assign dma.wr_go = go;

   // Read from the DMA when there is data available (!dma.empty) and when
   // there is still space in the absorption FIFO to absorb the result in the
   // case of a stall. Without an absorption FIFO, the condition would 
   // likely be: !dma.empty && !stalled
   assign dma.rd_en = !dma.empty && !fifo_almost_full;

   // Write to memory when there is a full cache line to write, and when the
   // DMA isn't full.
   assign dma.wr_en = (result_count_r == RESULTS_PER_CL) && !dma.full;

   // Write the data from the output buffer, which stores 8 separate results.
   assign dma.wr_data = output_buffer_r;

   // The AFU is done when the DMA is done writing all results.
   assign done = dma.wr_done;
            
endmodule




