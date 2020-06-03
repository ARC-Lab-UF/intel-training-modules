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
         
   // TODO: Instantiate the provided memory map to get the addressses of the
   // input and output arrays, the number of cache lines for the input array,
   // the go signal, and to send the done signal back to software.
   
   // TODO: Instantiate or define the required pipeline.
   // The hw/ip folder contains cores from the IP library for a floating-point
   // multiply and floating-point add. The latency of both cores is 3 cycles.
   // The sources are already included in hw/filelist.txt.
   // If you use separate cores, you must update hw/filelist.txt accordingly.
   
   // TODO: Pack the pipeline outputs into a complete cache line to write
   // to memory.

   // TODO: Handle all of the DMA interfacing. 
   
endmodule




