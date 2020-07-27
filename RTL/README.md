# Introduction

These examples illustrate how to design AFUs for the Intel PAC using RTL code. The [examples](examples/) folder includes simple examples that explain the basic concepts of AFU design. The [exercises](exercises/) folder contains practice examples that provide skeleton code to get started, along with completed solutions.

***IMPORTANT*** When running on the Intel DevCloud, make use to run [setup.sh](setup.sh) after cloning this repository to ensure that all examples have the required libraries and headers.
 
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
    - Note: make use to run [setup.sh](setup.sh) before running this or any of the following examples on the DevCloud.
    - [Video: DMA Hardware Abstraction Layer](https://youtu.be/q94xiWhug6c)
1. [Example: dma_loopback_uclk](examples/dma_loopback_uclk)
    - Description: An extension of the dma_loopback example that runs the AFU on the programmable user clock (uclk) instead of the primary clock.
1. [Exercise: simple_pipeline](exercises/simple_pipeline)
    - Description: Builds on top of the DMA examples to create a simple pipeline that performs a multiply-add tree on a stream of inputs from an array in the host-processor's memory, while producing an output stream that is written to a separate array in memory.
1. [Exercise: float_pipeline](exercises/float_pipeline)
    - Description: Same as the simple_pipeline example, but with floating-point resources. Uses cores from the Intel IP Library, along with a modified simulation script. 

# [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions)

# Simulation Instructions:

  Unless stated differently for a specific example, the following instructions should 
  work for simulating an AFU and corresponding software. **Note that The Intel DevCloud does not currently
  have simulation licenses, so this must currently be done locally. All examples
  were tested with Modelsim SE-64 10.5c.**

  Before simulating, ensure that the OPAE SDK is properly installed.  
  OPAE SDK scripts must be on PATH and include files and libraries must be available
  to the C compiler.  In addition, ensure that the OPAE_PLATFORM_ROOT
  environment variable is set. Some examples will also require the installation
  of the Intel FPGA Basic Building Blocks (BBB): https://github.com/OPAE/intel-fpga-bbb.
  The provided [setup.sh](setup.sh) script will download and install the BBB for use
  on the DevCloud.

  Simulation requires two software processes: one for RTL simulation and
  the other to run the connected software.  To construct an RTL simulation
  environment, execute the following in the directory containing this
  README:

    $ afu_sim_setup --source hw/filelist.txt sim

  This will construct an ASE environment in the *sim* subdirectory.  If
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
  

# Synthesis Instructions:

  RTL simulation and synthesis are driven by the same filelist.txt and
  underlying OPAE scripts.  To construct a Quartus synthesis environment
  for this AFU, enter:

    $ afu_synth_setup --source hw/filelist.txt synth
    $ cd synth
    $ ${OPAE_PLATFORM_ROOT}/bin/run.sh

  run.sh will invoke Quartus, which must be properly installed along with the OPAE SDK if you are not on the DevCloud.  The end
  result will be a file named afu.gbs in the synth directory. Next, load the bitfile onto the PAC as 
  specified in the [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions).
  
  If you get errors when running these scripts, see the [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions) for how to synthesize and configure a PAC with the resulting bitfile. If not running on the
  DevCloud, make sure Quartus and the OPAE SDK are installed, with all environment variables set according to the installation
  instructions.
 
  To execute the software application, run the following:
  
    $ ./afu
  
  Make sure to not run the simulation verision ./afu_ase.
  
  Some examples will also require the installation of the Intel FPGA Basic Building Blocks (BBB): https://github.com/OPAE/intel-fpga-bbb.
  The provided [setup.sh](setup.sh) script will download and install the BBB for use on the DevCloud.

