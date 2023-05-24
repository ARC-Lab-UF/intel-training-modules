# Vector Addition

These programs provide a basic introduction to SYCL and DPC++ using a vector addition example. All of the following implementations create a vectorized version of the following code:

    for (int i=0; i < VECTOR_SIZE; i++)
        out[i] = in1[i] + in2[i];

"Vectorization" refers to performing multiple instances of the same operation in parallel. In this case, we are using vectorized adds to speed up the execution of code that
adds all the corresponding elements from two vectors.

IMPORTANT: Make sure to read through all comments for an explanation of the code.

1. [vector_add_bad.cpp](vector_add_bad.cpp)
    - Basic tutorial into basic SYCL constructs: queues, handlers, kernels, buffers, accessors.
    - Demonstrates a common bug with accessors.
    - NOTE: This example intentionally has an incorrect output.
1. [vector_add1.cpp](vector_add1.cpp)
    - Corrects the bug from the previous example by demonstrating two different methods of ensuring output data is transferred back to the host.
1. [vector_add2.cpp](vector_add2.cpp)
    - Adds exception handling for host excecptions to previous example, which also fixes the original bug.
1. [vector_add_terse.cpp](vector_add_terse.cpp)
    - Demonstrates a semantically equivalent version of the previous example with a more concise coding style.
  
## Compilation and Execution Instructions

First, make sure you have logged on to a suitable node [(see here)](../../../SYCL#devcloud-usage-instructions).

To compile all examples, simply type:

`make`

This will generate an executable for each example that you can run with:

`./vector_add_bad`
`./vector_add1`
`./vector_add2`
`./vector_add_terse`
etc.

If you want to compile a specific example, type

`make example_name` where example_name is a .cpp file (but without the .cpp extension).
