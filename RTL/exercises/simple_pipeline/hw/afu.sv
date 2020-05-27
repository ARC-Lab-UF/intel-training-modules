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
// Project:      dma_loopback
// Description:  This AFU provides a loopback DMA test that simply reads
//               data from one array in the CPU's memory and writes the
//               received data to a separate array. The AFU uses MMIO to
//               receive the starting read adress, starting write address,
//               size (# of cache lines to read/wite), and a go signal. The
//               AFU asserts a done signal to tell software that the DMA
//               transfer is complete.
//
//               One key difference with this AFU is that it does not use
//               CCI-P, which is abstracted away by a hardware abstraction
//               layer (HAL). Instead, the AFU uses a simplified MMIO interface
//               and DMA interface.
//
//               The MMIO interface is defined in mmio_if.vh. It behaves
//               similarly to the CCI-P functionality, except only supports
//               single-cycle MMIO read responses, which eliminates the need
//               for transaction IDs. MMIO writes behave identically to
//               CCI-P.
//
//               The DMA read interface takes a starting read address (rd_addr),
//               and a read size (rd_size) (# of cache lines to read). The rd_go
//               signal starts the transfer. When data is available from memory
//               the empty signal is cleared (0 == data available) and the data
//               is shown on the rd_data port. To read the data, the AFU should
//               assert the read enable (rd_en) (active high) for one cycle.
//               The rd_done signal is continuously asserted (active high) after
//               the AFU reads "size" words from the DMA.
//
//               The DMA write interface is similar, again using a starting
//               write address (wr_addr), write size (wr_size), and go signal.
//               Before writing data, the AFU must ensure that the write
//               interface is not full (full == 0). To write data, the AFU
//               puts the corresponding data on wr_data and asserts wr_en
//               (active high) for one cycle. The wr_done signal is continuosly
//               asserted after size cache lines have been written to memory.
//
//               All addresses are virtual addresses provided by the software.
//               All data elements are cachelines.
//

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
   localparam int RESULT_WIDTH = 64;
   localparam int INPUTS_PER_CL = CL_DATA_WIDTH / INPUT_WIDTH;   // 16
   localparam int RESULTS_PER_CL = CL_DATA_WIDTH / RESULT_WIDTH; // 8
   
   // Normally I would make this a function of the number of inputs, but since
   // the pipeline is hardcoded for a specific number of inputs in this example,
   // this will suffice.
   localparam int PIPELINE_LATENCY = 5;
   
   // 512 is the shallowest a block RAM can be, so there's no point in making
   // it smaller unless using MLABs instead.
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
   // 64-bit virtual byte addresses, a transfer size (in cache lines), and a
   // go signal. It also sends a done signal back to software.
   memory_map
     #(
       .ADDR_WIDTH(VIRTUAL_BYTE_ADDR_WIDTH),
       .SIZE_WIDTH(CL_ADDR_WIDTH+1)
       )
     memory_map (.*);

   logic [INPUT_WIDTH-1:0] pipeline_inputs[INPUTS_PER_CL];

   // Slice the DMA read data into 16 separate 32-bit inputs.
   always_comb begin
      for (int i=0; i < INPUTS_PER_CL; i++) begin
	 pipeline_inputs[i] = dma.rd_data[INPUT_WIDTH*i +: INPUT_WIDTH];
      end      
   end

   logic pipeline_valid_out;
   logic [RESULT_WIDTH-1:0] pipeline_result;
      
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
   // inputs to the FIFO during a stall and "absorbing" the existing contents 
   // of the pipeline. See the following paper for more details:
   //
   // M. N. Emas, A. Baylis and G. Stitt, "High-Frequency Absorption-FIFO 
   // Pipelining for Stratix 10 HyperFlex," 2018 IEEE 26th Annual International 
   // Symposium on Field-Programmable Custom Computing Machines (FCCM), 
   // Boulder, CO, 2018, pp. 97-100, doi: 10.1109/FCCM.2018.00024.
   fifo 
     #(
       .WIDTH(RESULT_WIDTH),
       .DEPTH(FIFO_DEPTH),
       .ALMOST_FULL_COUNT(FIFO_DEPTH-PIPELINE_LATENCY)
       )
   absorption_fifo 
     (
      .clk(clk),
      .rst(rst),
      .rd_en(fifo_rd_en),
      .wr_en(pipeline_valid_out),
      .empty(fifo_empty),
      .full(),
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
   // a full cache line) to write to memory.
   logic output_buffer_full;
   assign output_buffer_full = result_count_r == RESULTS_PER_CL;      
   
   // Read from the absorption FIFO when there is data in it, and when the 
   // output buffer is not full.     
   logic fifo_rd;
   assign fifo_rd = !fifo_empty && !output_buffer_full;   
   
   // Pack results into a cache line to write to memory.
   always_ff @ (posedge clk or posedge rst) begin
      
      if (rst) begin
	 result_count_r <= '0;
      end
      else begin	 
	 // Whenever something is read from the absorption fifo, shift the 
	 // output buffer to the right and append the data from the FIFO to 
	 // the front of the buffer.	 
	 if (fifo_rd) begin
	    output_buffer_r <= {fifo_rd_data, 
				output_buffer_r[CL_DATA_WIDTH-1:RESULT_WIDTH]};

	    // Track the number of results in the output buffer. There is
	    // a full cache line when result_count_r reaches RESULTS_PER_CL.
	    result_count_r ++;
	 end

	 // Every time the DMA writes a cache line, reset the result count.
	 if (dma.wr_en) begin
	   result_count_r <= '0;
	 end        		 
      end
   end // always_ff @
      
   // Assign the starting addresses from the memory map.
   assign dma.rd_addr = rd_addr;
   assign dma.wr_addr = wr_addr;
   
   // Use the input size (# of input cache lines) specified by software.
   assign dma.rd_size = input_size;

   // For every input cache line, we get 16 32-bit inputs. These inputs produce
   // one 64-bit output. We can store 8 outputs in a cache line, so there is
   // one output cache line for every 8 input cache lines.
   assign dma.wr_size = input_size >> 3;

   // Start both the read and write channels when the MMIO go is received.
   // Note that writes don't actually occur until dma.wr_en is asserted.
   assign dma.rd_go = go;
   assign dma.wr_go = go;

   // Read from the DMA when there is data available (!dma.empty) and when
   // there is still space in the absorption FIFO to absorb the result in the
   // case of a stall. Without an absorption FIFO, the condition would 
   // likely be: !dma.empty && !dma.full
   assign dma.rd_en = !dma.empty && !fifo_almost_full;

   // Write to memory when there is a full cache line to write, and when the
   // DMA isn't full.
   assign dma.wr_en = (result_count_r == RESULTS_PER_CL) && !dma.full;

   // Write the data from the output buffer, which stores 8 separate results.
   assign dma.wr_data = output_buffer_r;

   // The AFU is done when the DMA is done writing size cache lines.
   assign done = dma.wr_done;
            
endmodule




