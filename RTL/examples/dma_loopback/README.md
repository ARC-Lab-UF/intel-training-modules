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

This example demonstrates how to read from and write to the host-processor's memory from the AFU. Due to the difficulties of
using CCI-P directly for accessing RAM, the example introduces a hardware-abstraction layer (HAL) that provides a simple
DMA interface. The AFU uses that DMA interface to provide simple loopback functionality that reads an input array from memory
and then writes the corresponding data to a different array. Corresponding software initializes the input array and verifies
that the output array is the same as the input array after FPGA execution.

- [Video: Explanation of HAL DMA interface](https://www.youtube.com/watch?v=q94xiWhug6c)
- [Slides](./dma_hal.pptx)

In addition to demonstrating DMA functionality, this example shows how to modify the default synthesis options created by the afu_synth_setup script. Within the hw/ folder, there is an [hw/afu.qsf](hw/afu.qsf) file that contains a synthesis option to enable pass-through logic on inferred RAMs on the fifo module. Although whenever possible, pass-through logic should be avoided, it is required by a provided FIFO in this example. Without this option, the code does not work on the PAC because the generated Quartus setting disable the required pass-through logic.

To enable the afu_synth_setup script to add this qsf file to the generated quartus project, the sources file [hw/filelist.txt](hw/filelist.txt) contains the following line:
 
```
QI:afu.qsf
```

The QI: prefix tells the scripts that the corresponding file contains Quartus settings. In the same sources file, there is another  line with new functionality:

```
C:${FPGA_BBB_CCI_SRC}/BBB_cci_mpf/hw/rtl/cci_mpf_sources.txt
```

The C: prefix tells the scripts to recursively add the specified file as additional sources. The corresponding file in this case defines the sources for the Intel MPF Basic Building Block, which handles all virtual-to-physical address translation, and data reordering.

# [Simulation Instructions](https://github.com/ARC-Lab-UF/intel-training-modules/blob/master/RTL/#simulation-instructions)
# [Synthesis Instructions](https://github.com/ARC-Lab-UF/intel-training-modules/tree/master/RTL#synthesis-instructions)
# [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions)

 
