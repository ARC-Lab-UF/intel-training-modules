# Introduction

This exercise illustrates how to improve timing by reducing fanout on reset signals by removing the reset from registeres that don't absolutely need it.
The provided files use a clock constraint of 200 MHz, which Quartus cannot achieve for the unoptimized code.

All code is provided in src/multiple_add.sv. The file contains two implementations of a simple pipeline: one where all registers are reset, and one where only a minimal number of registers ar reset.

# Instructions

1. In Quartus, open the multiple_add.qpf project.
1. Open the src/multiple_add.sv.
1. Go to the bottom of the file and find the multiple_add module. This modules acts as a top level that lets you change which implementation is used.
1. Make sure the multiple_add_full_reset module is instantiated from the multiple_add module by uncommenting it. Make sure all other instantiations are commented out.
1. Compile the design.
1. Run the timing analyzer to identify the bottlneck.
1. Change the multiple_add module to instantiate multiple_add_min_reset.
1. Compile and run the timing analyzer.
1. Note the improved clock frequencies from simply removing resets.

