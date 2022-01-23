# Introduction

This exercise illustrates how to improve timing for fanout bottlenecks by applying register duplication. 
The provided files use a clock constraint of 200 MHz, which Quartus cannot achieve for the unoptimized code.

All code is provided in src/multiple_add.sv. The file contains several different implementations of a module that registers a single input, and then fans out that input to a configurable number of adders. That fanout creates timing bottlenecks that some of the modules resolve using register duplication in different ways.

# Instructions

1. In Quartus, open the multiple_add.qpf project.
1. Open the src/multiple_add.sv.
1. Go to the bottom of the file and find the multiple_add module. This modules acts as a top level that lets you change which implementation is used.
1. Make sure the multiple_add_slow module is instantiated from the multiple_add module by uncommenting it. Make sure all other instantiations are commented out.
1. Compile the design.
1. Run the timing analyzer to identify the bottlneck.
1. Change the multiple_add module to instantiate multiple_add_auto_reg_dup1.
1. Repeat the above steps for all of the other modules and note how the clock changes for each approach.

