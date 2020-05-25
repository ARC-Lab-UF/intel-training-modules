# MMIO_ADD Exercise

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

This example illustruates a simple AFU that implements an adder. Software
running on the host processor sends inputs to the adder and reads outputs from
the adder over MMIO. 

To complete the exercise, the user must create a 64-bit adder with registered
inputs and outputs that should be memory mapped for communication of CCI-P.
The software should then write to the input registers of the adder and read from
the output register over CCI-P to perform a number of add operations.

To perform the exercise, use the code in the [code directory](code/). All RTL
modifications should be made in [code/hw/afu.sv](code/hw/afu.sv). Search the comments for TODO
statements that explain what needs to be done. Do the same for the software
by completing the TODO statements in [code/sw/main.cpp](code/sw/main.cpp).

Note that this example is purely for explanation of how to create AFUs. An 
AFU that simply implements an adder would be very inefficent compared to just
doing the addition in software.

[A completed solution is available in solution/](solution/) for comparison once the user has
completed the exercise.

# [Simulation Instructions](https://github.com/ARC-Lab-UF/intel-training-modules/blob/master/RTL/#simulation-instructions)
# [Synthesis Instructions](https://github.com/ARC-Lab-UF/intel-training-modules/tree/master/RTL#synthesis-instructions)
# [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions)

