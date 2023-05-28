# Introduction to SYCL for FPGAs

This example shows the basics of how to write SYCL code targeting FPGAs, using the SAXPY example from earlier in the tutorial:

    for (int i=0; i < VECTOR_SIZE; i++)
        z[i] = a * x[i] + y[i];

FPGAs are a unique architecture and often benefit from different types of parallelism than GPUs and CPUs. Whereas those
architectures are generally optimized for vectorization or SIMD/SIMT parallelism, FPGAs often perform better when
exploiting "deep" pipeline parallelism. FPGAs are capable of vectorization also, but pipelining is usually a better
strategy when an application is amenable to pipelining.

IMPORTANT: Make sure to read through all comments for an explanation of the code.

1. [saxpy_single.cpp](saxpy_single.cpp) 
    - Basic version of FPGA SAXPY using the single_task construct instead of a parallel_for.
    - Demonstrates how FPGA implementations commonly use single_task with a loop, as opposed to finer-grained computation in a parallel_for.
    - High-level synthesis (i.e., compilation) will pipeline this implementation.
    - Demonstrates the FPGA emulator selector, which allows us to see FPGA functionality (not not performance) without having to wait for length FPGA compilation.
1.  [saxpy_unroll.cpp](saxpy_unroll.cpp)
    - Similar to previous example, but adds a pragma for unrolling the loop.
    - Unrolling is conceptually similar to vectorization, performing more than one iteration at a time.
1. [saxpy_pipe.cpp](saxpy_pipe.cpp)
    - Demonstrates "deep" task-level parallelism by decomposing the SAXPY code into two kernels and communicating between those kernels using pipes.
    - NOTE: Like the earlier multi-kernel SAXPY examples, this example is largely artificial and is solely intended how to achieved communication between tasks via pipes.
    
## Compilation and Execution Instructions

First, make sure you have logged on to a suitable node [(see here)](../../../SYCL#devcloud-usage-instructions). Note that these FPGA examples
require nodes with FPGAs, so make sure to choose a node using something like this:

`qsub -I -l nodes=1:fpga:ppn=2`

To compile all examples, simply type:

`make`

This will generate an executable for each example that you can run with:

`./saxpy_single`
`./saxpy_unroll`
`./saxpy_pipe`
etc.

If you want to compile a specific example, type:

`make example_name` where example_name is a .cpp file (but without the .cpp extension).
