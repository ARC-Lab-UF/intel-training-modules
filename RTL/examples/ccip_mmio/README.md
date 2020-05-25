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

This example explains basic memory-mapped IO communication using the 
Core Cache Interface protocol (CCI-P). It builds on top of the basic hello_afu 
example provided by Intel at:

https://github.com/OPAE/opae-sdk/tree/master/samples/hello_afu

The AFU in this example provides the bare-minimum MMIO functionality required
by any AFU, and adds a single user register that software running on the
host processor can access.

One key difference from the hello_afu example is the use of a simplified
AFU C++ class that wraps some of the basic OPAE functionality to make it
easier to get started. 

* [Slides that explain CCI-P and the corresonding SystemVerilog code](./intel_pac_rtl_ccip.pptx).
* [A video presentation of the slides](https://youtu.be/e03xuTsQ4fQ)

# [Simulation Instructions](https://github.com/ARC-Lab-UF/intel-training-modules/blob/master/RTL/#simulation-instructions)
# [Synthesis Instructions](https://github.com/ARC-Lab-UF/intel-training-modules/tree/master/RTL#synthesis-instructions)
# [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions)


