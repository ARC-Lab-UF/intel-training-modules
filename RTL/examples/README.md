# Introduction

These examples illustrate how to design AFUs for the Intel PAC using RTL code.

- ccip_mmio: Explains the basics of Core Cache Interface Protocol (CCI-P) and how to communicate from software to the FPGA over memory-mapped I/O (MMIO)

- ccip_mc_read: Explains how to do multi-cycle MMIO reads and how to interface with resources other than register (e.g. block RAM).

- dma_loopback: Explains how to access the host-processor's memory from the FPGA using a hardware abstraction layer that provides a simple DMA interface.

# DevCloud Instructions

- [Explanation for how to register, connect, and use the DevCloud for these exercises](https://github.com/intel/FPGA-Devcloud).

- [Quickstart Guide for Arria 10 PAC](https://github.com/intel/FPGA-Devcloud/tree/master/main/QuickStartGuides/RTL_AFU_Program_PAC_Quickstart/Arria10)

- To clone this repository on the DevCloud, login after using the above instructions and then run: 
    
    git clone https://github.com/ARC-Lab-UF/intel-training-modules.git
