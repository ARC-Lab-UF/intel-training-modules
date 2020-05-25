# Introduction

These examples illustrate how to design AFUs for the Intel PAC using RTL code.

- ccip_mmio: Explains the basics of Core Cache Interface Protocol (CCI-P) and how to communicate from software to the FPGA over memory-mapped I/O (MMIO)

- ccip_mc_read: Explains how to do multi-cycle MMIO reads and how to interface with resources other than register (e.g. block RAM).

- dma_loopback: Explains how to access the host-processor's memory from the FPGA using a hardware abstraction layer that provides a simple DMA interface.
