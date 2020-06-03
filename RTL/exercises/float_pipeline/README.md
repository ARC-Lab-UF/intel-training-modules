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

In this example, you will be created a modified version of the [simple_pipeline](../simple_pipeline) example. In this example, all operations are 32-bit floats. The structure of the pipeline should be identical, expect now all multiplications and adds use floating-point resources. To perform floating-point opeartions, you generally use cores from the Intel IP Library within Quartus. The hw/ip folder already provides an IP core for both a floating-point multiply and floating-point add. Each core has a latency of 3 cycles. There is an instantiation template within each corresponding folder. See documentation for the Intel IP Library for more details. Note that these cores may need to be regenereated depending on the version of Quartus you are using. If you modify the cores, make sure to update hw/filelist.txt accordingly with all the simulation source files and ip file.

Like the [simple_pipeline](../simple_pipeline) example, the AFU needs to pack multiple outputs into a single cache line. However, for this example, the results are 32-bit floats instead of 64-bit integers, so there will be twice as many outputs per cache line. Make sure to adapt the previous code for this new number of outputs.

The provided software is identical, except with all inputs and outputs using 32-bit floats. One issue with floating point is that you can't directly compare equality between software and the AFU because of the non-associativity of floating-point operations. Because the AFU performs the operations in a different order than software, the outputs are *slightly* different. Within sw/config.h, there is a threshold defined for an acceptable error percentage. The software uses this amount to determine correctness. 

# [Simulation Instructions](https://github.com/ARC-Lab-UF/intel-training-modules/blob/master/RTL/#simulation-instructions)

**Example-Specific Simulation Instructions:** When simulating cores from the IP library, you must first make sure that simulation libraries have been compiled. Depending on your specific version of afu_sim_setup, and the IP cores you are using, the script might not do this for you. To make simulation as transparent as possible, this example includes a [fix_sim.sh](solution/fix_sim.sh) script that corrects the generated ASE project so that it works with the IP cores. To use the script, simply run it on the simulation directory created by afu_sim_setup:

```
afu_sim_setup -s hw/filelist.txt sim
./fix_sim.sh sim
```

For some IP cores, the fix_sim.sh might need to be modified. For example, some cores have a hex file that needs to be copied into the simulations work/ directory. It is possible that future versions of afu_sim_setup will do this, but such functionality was not available at the time of these tests.

This script will also copy a vsim_run.tcl file that you can modify to display whatever signals you would like to see in the waveform. Make changes in the custom_sim/vsim_run.tcl file before runing fix_sim.sh. See the [simple_pipeline](../simple_pipeline) example for more details about signals missing from the simulation waveform.

A similar issue commonly occurs for block RAM resources, which can be added in the same way, or can be automatically added as described in the [mmio_mc_read](../../examples/mmio_mc_read) example.

# [Synthesis Instructions](https://github.com/ARC-Lab-UF/intel-training-modules/tree/master/RTL#synthesis-instructions)
# [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions)

 
