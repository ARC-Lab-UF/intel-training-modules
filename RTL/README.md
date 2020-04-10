# Introduction

These examples illustrate how to design AFUs for the Intel PAC using RTL code. The [examples](examples/) folder includes simple examples that explain the basic concepts of AFU design. The [exercises](exercises/) folder contains practice examples that provide skeleton code to get started, along with completed solutions.

# Suggested Study Order

1. [Video: Intel PAC Overview](https://youtu.be/14cGHio8ml4)
    - [Slides](examples/ccip_mmio/intel_pac_rtl_ccip.pptx)    
2. [Example: ccip_mmio](examples/ccip_mmio)
    - [Slides](examples/ccip_mmio/intel_pac_rtl_ccip.pptx)
    - Description: Illustrates how to create a basic AFU that provides a memory-mapped register, and how to communicate with that register from C++ software.
3. [Exercise: mmio_add](exercises/mmio_add)    
    - Description: Simple AFU adder with memory-mapped input and output registers that can be accessed from C++ software.
4. [Exercise: mmio_fib](exercises/mmio_fib)
    - Description: Fibonacci calculator AFU that communicates with software over MMIO to receive inputs, signal completion, and provide outputs.    
5. Exercise: mmio_ram
    - Descrition: ADDLATER

# DevCloud Instructions

[Explanation for how to register, connect, and use the DevCloud for these exercises](https://github.com/intel/FPGA-Devcloud).



