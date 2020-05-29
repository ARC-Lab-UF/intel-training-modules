# MMIO_FIB Exercise

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

This example illustrutes a simple AFU that implements a Fibonacci calculator. 
Software running on the host processor sends an input *n* to the AFU, which 
specifies the which Fibonacci number to calculate. The software then sends a *go*
signal to the AFU, and then continuously reads a *done* signal until the AFU
has completed. Upon completion, software reads the result from the AFU. 
All communication is handled over MMIO.

To complete the exercise, the user must implement the corresponding memory map
that implements the communication described above. All memory map functionality 
should be made in [code/hw/memory_map.sv](code/hw/memory_map.sv).

After implementing the memory map, the user should complete the exercise by 
creating the Fibonacci calculator within [code/hw/fib.sv](code/hw/fib.sv).
No other files need to be modified.

Search the comments for TODO statements that explain what needs to be done. 
Do the same for the software by completing the TODO statements in [code/sw/main.cpp](code/sw/main.cpp).

[A completed solution is available in solution/](solution/) for comparison once the user has
completed the exercise.

# [Simulation Instructions](https://github.com/ARC-Lab-UF/intel-training-modules/blob/master/RTL/#simulation-instructions)
# [Synthesis Instructions](https://github.com/ARC-Lab-UF/intel-training-modules/tree/master/RTL#synthesis-instructions)
# [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions)

