# Introduction

This example illustrates different how 10-series FPGAs can implement 3-input
adders with the same number of resources as a 2-input adder. See adder_3input.pptx for an explanation.

All code is provided in src/adder_3input.sv and src/adder_3input_timing.sv. 

# Instructions

1. In Quartus, open the adder_3input.qpf project (THIS REQUIRES QUARTUS PRIME PRO).
1. Open src/adder_3input.sv.
1. Compile the design and check the resource requirements (after fitting).
1. Change the adder_3input module to use a 2-input adder.
1. Recompile and check resource requirements.
1. Change the top-level file to add_sub_timing.sv.
1. Repeat the same experiments as before, but not make note of the clock frequencies after timing analysis.



