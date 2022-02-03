# Introduction

This example illustrates different implementations of an adder/substractor,
along with the corresponding tradeoffs. The code also includes a normal adder
in order to conveniently compare resources and clock frequency.

All code is provided in src/add_sub.sv. 

# Instructions

1. In Quartus, open the add_sub.qpf project (THIS REQUIRES QUARTUS PRIME PRO).
1. Open src/add_sub.sv.
1. Go to the bottom of the file and find the add_sub module. This modules acts as a top level that lets you change which implementation is used.
1. Compile the design and check the resource requirements (after fitting).
1. Change the add_sub module to instantiate a different implementation.
1. Recompile and check resource requirements.
1. Repeat for all implementations.
1. Change the top-level file to add_sub_timing.sv.
1. Repeat the same experiments as before, but not make note of the clock frequencies after timing analysis.



