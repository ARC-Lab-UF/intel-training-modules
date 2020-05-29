License Statement:  GPL Version 3
---------------------------------
Copyright (c) 2020 University of Florida

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

For the details of the GNU General Public License, see the included
gpl.txt file, or go to http://www.gnu.org/licenses/.

# Introduction

It is highly recommended that the reader attempt this exercise after studying the [previous examples and exercises shown here](../../../RTL#suggested-study-order).

In this example, you will be creating a simple pipeline in an AFU. The pipeline streams an array of 32-bit unsigned integers from an input array in the host-processors memory. The pipeline takes 16 of those integers as inputs, multipliers the 8 pairs of inputs (to provide 8 64-bit products), and then sums the 8 products into a 64-bit result (the adds ignore carries). The output of the pipeline is written to a separate output array in memory. However, because the DMA interface only allows writing entire cache lines (512 bits), the AFU must first pack 8 separate outputs (512 bits) to avoid gaps between results in memory. 

To ensure that the AFU doesn't have to deal with partial cache lines on the last transfer, the software assures that the number of inputs and outputs are a multiple of the required amount to always provide complete cache line outputs. Although the provided solution provides this funtionality, the AFU can be extended to support any number of outputs, which is left to the reader as an exercise.

The provided software instantiates the AFU, allocates inputs and output arrays within memory, initializes those arrays, and transfers configuration information to the AFU over MMIO. Software provides the virtual byte address of the input and output memory, and also specifies the size of the input stream to read from memory in terms of number of cachelines. The software also sends a go signal over MMIO, waits until the AFU is complete by reading from a done signal over MMIO, and then verifies the contents of the output array are correct.

- [Video: Explanation of HAL DMA interface](https://www.youtube.com/watch?v=q94xiWhug6c)
- [Slides](./dma_hal.pptx)

# [Simulation Instructions](https://github.com/ARC-Lab-UF/intel-training-modules/blob/master/RTL/#simulation-instructions)
# [Synthesis Instructions](https://github.com/ARC-Lab-UF/intel-training-modules/tree/master/RTL#synthesis-instructions)
# [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions)

 
