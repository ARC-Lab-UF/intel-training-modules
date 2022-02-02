# Introduction

This example illustrates how two semantically equivalent modules in terms
of simulated behavior can synthesize into significantly different circuits
with considerable area and timing differences.

The module used in this example is synthetic, but is representative of
functionality included in a variety of real circuits (e.g., FIFOs). The
count module maintains an internal count based on the down and up control
signals. Unlike a standard down/up counter, which can either count up or down
in a given cycle, this count module can count up and down. Such functionality
is often needed to track the number of elements in a buffer, pending data
within a pipeline, etc.

All code is provided in src/count.sv. 

# Instructions

1. In Quartus, open the count.qpf project.
1. Open the src/count.sv.
1. Go to the bottom of the file and find the count module. This modules acts as a top level that lets you change which implementation is used.
1. Make sure the count_slow module is instantiated by uncommenting it. Make sure all other instantiations are commented out.
1. Compile the design and check the clock frequencies.
1. Change the count module to instantiate the count_fast module.
1. Compile the design and check the new clock frequencies. 


