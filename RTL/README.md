# Introduction

These examples illustrate how to design AFUs for the Intel PAC using RTL code. The [examples](examples/) folder includes simple examples that explain the basic concepts of AFU design. The [exercises](exercises/) folder contains practice examples that provide skeleton code to get started, along with completed solutions.


# Suggested Study Order

1. [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions)
1. [Video: Intel PAC Overview](https://youtu.be/HatHuLtZ5-0), [Slides](../intel_pac_overview.pptx)   
1. [Example: ccip_mmio](examples/ccip_mmio)
    - Description: Illustrates how to create a basic AFU that provides a memory-mapped register, and how to communicate with that register from C++ software.
    - [Video: CCI-P Explanation](https://www.youtube.com/watch?v=e03xuTsQ4fQ), [Slides](examples/ccip_mmio/intel_pac_rtl_ccip.pptx)
    - [Video: ccip_mmio RTL Code Demonstration](https://www.youtube.com/watch?v=3WXo1qzYTvs)
    - [Video: ccip_mmio SW Code Demonstration](https://www.youtube.com/watch?v=Qed4ooAeepw)
1. [Video: Intel ASE (AFU Simulation Evironment) Demonstration](https://youtu.be/HI2gSz_MXjc)
1. [Video: Synthesizing AFU and Configuring PAC on the DevCloud](https://youtu.be/QPjkVo3gSb0)
1. [Exercise: mmio_add](exercises/mmio_add)    
    - Description: Simple AFU adder with memory-mapped input and output registers that can be accessed from C++ software.
1. [Exercise: mmio_fib](exercises/mmio_fib)
    - Description: Fibonacci calculator AFU that communicates with software over MMIO to receive inputs, signal completion, and provide outputs.    
1. [Example: mmio_mc_read](examples/mmio_mc_read)
    - Description: Illustrates how to use CCI-P to implement multi-cyle MMIO reads to inferface with resources other than registers.
    - [Video: Explanation of multi-cycle MMIO reads](https://youtu.be/Xj1Clq4ac8E), [Slides](examples/mmio_mc_read/mmio_mc_read.pptx)
1. [Example: dma_loopback](examples/dma_loopback)
    - Description: Illustrates how to read/write the host processor's memory from within the AFU using a hardware abstraction layer (HAL) that hides the complexities of CCI-P.
    - [Video: DMA Hardware Abstraction Layer](https://youtu.be/q94xiWhug6c)
    
    

