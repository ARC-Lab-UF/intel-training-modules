// Module Name:  afu.sv
// Project:      simple pipeline
// Description:  This AFU implements a simple pipeline that streams 32-bit
//               unsigned integers from an input array, with each cache line
//               providing 16 inputs. The pipeline multiplies the 8 pairs of
//               inputs from each input cache line, and sums all the products
//               to get a 64-bit result that is written to an output array.
//               All multiplications and additions should provide 64-bit
//               outputs, which means that the multiplications retain all
//               precision (due to their 32-bit inputs), but the adds due not
//               include carrys.
//
//               Since each output is 64 bits, the AFU must generate 8 outputs
//               before writing a cache line to memory (512 bits). The AFU
//               uses output buffering to pack 8 separate 64-bit outputs into
//               a single 512-bit buffer that is then written to memory.
//
//               Although the AFU could be extended to support any number of
//               inputs and/or outputs, software ensures that the number of
//               inputs is a multiple of 16, so the AFU doesn't have to consider
//               the situation of ending without 8 results in the buffer to
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
   
   // TODO: Pack the pipeline outputs into a complete cache line to write
   // to memory.

   // TODO: Handle all of the DMA interfacing. 
      
            
endmodule




