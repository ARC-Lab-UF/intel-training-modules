# Introduction

These examples illustrate how to design AFUs for the Intel PAC using RTL code. 

- [ccip_mmio](ccip_mmio/): Explains the basics of Core Cache Interface Protocol (CCI-P) and how to communicate from software to the FPGA over memory-mapped I/O (MMIO)

- [ccip_mc_read](ccip_mc_read/): Explains how to do multi-cycle MMIO reads and how to interface with resources other than register (e.g. block RAM). Demonstrates how to get Modelsim to include block RAM signals in the waveform.

- [dma_loopback](dma_loopback): Explains how to access the host-processor's memory from the FPGA using a hardware abstraction layer that provides a simple DMA interface.

- [dma_loopback_uclk](dma_loopback): Explains how to run the AFU off the programmable user clk (uclk) instead of the primary clock. Uses the same dma_loopback example with just a different JSON file, and minor code changes to measure the clock frequency on the FPGA.

# [Suggested Study Order](https://github.com/ARC-Lab-UF/intel-training-modules/tree/master/RTL#suggested-study-order)
