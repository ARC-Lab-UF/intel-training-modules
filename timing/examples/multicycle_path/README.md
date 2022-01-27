# Introduction

This example illustrates a multicycle path optimization. See the corresponding
powerpoint [multicycle_paths.pptx](multicycle_paths.pptx) for an explanation.

All code is provided in [src/multicycle_path.sv](src/multicycle_path.sv). 

# Instructions

1. In Quartus, open the multicycle_path.qpf project.
1. Open [src/multicycle_path.sv](src/multicycle_path.sv).
1. Go to the bottom of the file and find the multicycle_path module. This module acts as a top level that lets you change which implementation is used.
1. Make sure the unoptimized module is instantiated from the multicycle_path module by uncommenting it. Make sure all other instantiations are commented out.
1. Compile the design and check the clock frequencies.
1. Change the multicycle_path module to instantiate the optimized module.
1. Compile the design and check the new clock frequencies. 


