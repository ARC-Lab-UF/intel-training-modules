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

To complete the exercise, the user must specify the AFU within code/hw/afu.sv. See the TODO comments for hints about what needs to be done. A completed memory map is provided in code/hw/memory_map.sv. Note that any new files created by the user must be added to [code/hw/filelist.txt](code/hw/filelist.txt). The complete software is provided in [code/sw/](code/sw), which does not require changes.

# [Simulation Instructions](https://github.com/ARC-Lab-UF/intel-training-modules/blob/master/RTL/#simulation-instructions)

**Example-Specific Simulation Instructions:** When using Intel ASE, it is common for Modelsim to exclude various signals from the waveform, especially arrays. Without those signals, debugging is nearly impossible. This issue is demonstrated within the provided solution for this example, where none of the internal signals within [solution/hw/pipeline.sv](solution/hw/pipeline.sv) are included in the waveform. Fortunately, the signals can be added manually before the simulation starts. Look at [solution/hw/vsim_run.tcl](solution/hw/vsim_run.tcl) for an example of this. In that file, there are lines like the following:

```
add wave -expand /ase_top/platform_shim_ccip_std_afu/ccip_std_afu/hal/afu/pipeline/mult_out_r
```

This will add the array of multiplier-output registers to the waveform when the simulation is run. Repeat for other signals that you would like to monitor. For some reason, using the * will not add these signals, so to my knowledge that have to be specified individually with the complete path in the design hierarchy. Since it is easy to mistype this path, I usually open modelsim, find another signal within the module that I want, copy that design hierarchy path, and then just replace the signal name with the one I want to add.

To use this solution, create the simulation using the normal afu_sim_setup script, and then copy [solution/hw/vsim_run.tcl](solution/hw/vsim_run.tcl) into the created directory.

A similar issue commonly occurs for block RAM resources, which can be added in the same way, or can be automatically added as described in the [mmio_mc_read](../../examples/mmio_mc_read) example.

# [Synthesis Instructions](https://github.com/ARC-Lab-UF/intel-training-modules/tree/master/RTL#synthesis-instructions)
# [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions)

 
