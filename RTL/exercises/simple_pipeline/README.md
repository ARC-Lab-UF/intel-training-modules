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

In this example, you will be creating a simple pipeline in an AFU. 

This example demonstrates how to read from and write to the host-processor's memory from the AFU. Due to the difficulties of
using CCI-P directly for accessing RAM, the example introduces a hardware-abstraction layer (HAL) that provides a simple
DMA interface. The AFU uses that DMA interface to provide simple loopback functionality that reads an input array from memory
and then writes the corresponding data to a different array. Corresponding software initializes the input array and verifies
that the output array is the same as the input array after FPGA execution.

- [Video: Explanation of HAL DMA interface](https://www.youtube.com/watch?v=q94xiWhug6c)
- [Slides](./dma_hal.pptx)

# [Simulation Instructions](https://github.com/ARC-Lab-UF/intel-training-modules/blob/master/RTL/#simulation-instructions)
# [Synthesis Instructions](https://github.com/ARC-Lab-UF/intel-training-modules/tree/master/RTL#synthesis-instructions)
# [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions)

 
