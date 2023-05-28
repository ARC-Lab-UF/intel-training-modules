# Unified Shared Memory (USM)

In addition to the buffers and allocators that we have seen in all the examples so far, SYCL also provides
another communication method called Unified Shared Memory (USM). In these examples, we explain how to
use USM and evaluate the tradeoffs with buffers/allocators.

IMPORTANT: Make sure to read through all comments for an explanation of the code.

1. [usm_vs_buffers1.cpp](usm_vs_buffers1.cpp) 
    - Demonstrates the 3-types of allocation provided by USM.
    - Compares performance of simple copy operations using 3 USM-allocation methods, in addition to buffers/allocators.
1.  [usm_vs_buffers2.cpp](usm_vs_buffers2.cpp)
    - Modification to previous example where we intentionally only read 1 output.
    - While artificial here, this is common for reduction applications.
    - This example demonstrates that some implicit methods potentially read more outputs than necessary.
    
## Compilation and Execution Instructions

First, make sure you have logged on to a suitable node [(see here)](../../../SYCL#devcloud-usage-instructions).

To compile all examples, simply type:

`make`

This will generate an executable for each example that you can run with:

`./usm_vs_buffers1`
`./usm_vs_buffers2`
etc.

If you want to compile a specific example, type:

`make example_name` where example_name is a .cpp file (but without the .cpp extension).
