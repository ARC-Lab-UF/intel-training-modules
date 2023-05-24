# Vector Addition

These programs provide a basic introduction to SYCL and DPC++. 

* [vector_add_bad.cpp](vector_add_bad.cpp)
    * Simple SYCL program to showcase data management using queues, buffers, accessors, and kernels
    * Demonstrates a common bug.
  
* [vector_add1.cpp](vector_add1.cpp)
    * Corrects the bug from the previous example by demonstrating two different methods of ensureing output data is transferred back to the host.

* [vector_add2.cpp](vector_add2.cpp)
    * Adds exception handling to previous example
  
* [vector_add_terse.cpp](vector_add_terse.cpp)
    * Demonstrates a semantically equivalent version of the previous example with a more concise coding style.
  
## Compilation and Execution Instructions

First, make sure you have logged on to a suitable node (see here).

To compile all example, simply type:

`make`

This will generate an executable for each example that you can run with:

`./vector_add_bad
./vector_add1
./vector_add2
./vector_add_terse'
