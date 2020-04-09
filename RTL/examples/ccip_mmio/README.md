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

# Explanation

[Slides are included to explain CCI-P and the corresonding SystemVerilog code](./intel_pac_rtl_ccip.pptx).

A video presentation of the slides is available at ADDLATER.


# Simulation with ASE:

  If not running on the DevCloud, ensure that the OPAE SDK is properly installed.  
  OPAE SDK scripts must be on PATH and include files and libraries must be available
  to the C compiler.  In addition, ensure that the OPAE_PLATFORM_ROOT
  environment variable is set.

  A set of scripts is provided for running all the sample workloads.
  In this case, however, we will not use them.  Instead, we will introduce
  the underlying OPAE SDK scripts that they invoke.  AFU designers are free
  to incorporate either option into their workflows.

  Simulation requires two software processes: one for RTL simulation and
  the other to run the connected software.  To construct an RTL simulation
  environment execute the following in the directory containing this
  README:

    $ afu_sim_setup --source hw/filelist.txt sim

  This will construct an ASE environment in the build_sim subdirectory.  If
  the command fails, confirm that afu_sim_setup is on your PATH (in the
  OPAE SDK bin directory), that your Python version is at least 2.7 and
  that the jsonschema Python package is installed
  (https://pypi.python.org/pypi/jsonschema).

  To build and execute the simulator:

    $ cd sim
    $ make
    $ make sim

  This will build and run the RTL simulator.  If this step fails it is
  likely that your RTL simulator is not installed properly.  ModelSim,
  Questa and VCS are supported.

  The simulator prints a message that it is ready for simulation.  It also
  prints a message to set the ASE_WORKDIR environment variable.  Open
  another shell and cd to the directory holding this README.  To build and
  run the software:

    $ <Set ASE_WORKDIR as directed by the simulator>
    $ cd sw
    $ make clean
    $ make
    $ ./afu_ase

  Make sure to use the ./afu_ase executable and not the ./afe executable, 
  which will look for an actual FPGA and not an ASE simulation environment.
  
  To run the simulation without the verbose logging, do the following:
  
    $ ASE_LOG=0 ./afu_ase
  

# Synthesis with Quartus:

  RTL simulation and synthesis are driven by the same filelist.txt and
  underlying OPAE scripts.  To construct a Quartus synthesis environment
  for this AFU, enter:

    $ afu_synth_setup --source hw/filelist.txt synth
    $ cd synth
    $ ${OPAE_PLATFORM_ROOT}/bin/run.sh

  run.sh will invoke Quartus, which must be properly installed if you are not on the DevCloud.  The end
  result will be a file named afu.gbs in the synth directory.
  This GBS file may be loaded onto a compatible FPGA using OPAE's fpgaconf
  tool. If you are running on the DevCloud, here is an example:
    
    $ fpgaconf -B 0x3b afu.gbs
 
  To execute the software application, run the following:
  
    $ ./afu
  
  Make sure to not run the simulation verision ./afu_ase.
