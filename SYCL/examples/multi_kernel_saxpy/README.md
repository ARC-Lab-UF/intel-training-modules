# Using Multiple Kernels and SAXPY (Single-Precision A times X plus Y)

These code examples show extensions to SYCL to implement a single-precision A times X plus Y (saxpy), where A is a scalar and X and Y are vectors. Here is the corresponding psuedo-code:

    for (int i=0; i < VECTOR_SIZE; i++)
        z[i] = a * x[i] + y[i];

One new concept shown by this example is passing scalar parameters to kernels. You could potentially pass a scalar parameter to a kernel by creating a single-element buffer/accessor, but 
that requires a significant amount of code. This code shows how we can use C++ lambda capture lists to transfer scalar parameters. C++ technically allows us to pass any parameter
this way, but SYCL only supports it for certain basic types due to the complexity of transferring data to the device. For example, SYCL does not allow you to transfer a vector to
a kernel using a lambda capture list. It must be done with a buffer/accessor (or with USM).

The example also demonstrate common C++ problems with floating-point numbers.

IMPORTANT: Make sure to read through all comments for an explanation of the code.

1. [saxpy_multi_kernel.cpp](saxpy_multi_kernel.cpp) 
    - Modified version of SAXPY using integers. 
    - Demonstrates passing of scalars via lambda capture lists.
    - Tests random integer values between 0 and 100 for all inputs.  
1.  [saxpy_multi_device1.cpp](saxpy_multi_device1.cpp)
    - Similar code to the previous example, but uses single-precision real numbers.
    - Reports errors due to a common C++ bug, related to equality comparison of floating-point numbers.   
    - MAIN POINT: Never compare floats for equality.
1. [saxpy_device2.cpp](saxpy_device2.cpp)
    - Adds a function to replace equality comparison of floats to instead provide "sufficiently equal" comparisons.
    
## Compilation and Execution Instructions

First, make sure you have logged on to a suitable node [(see here)](../../../SYCL#devcloud-usage-instructions).

To compile all examples, simply type:

`make`

This will generate an executable for each example that you can run with:

`./saxpy_multi_kernel`
`./saxpy_multi_device1`
`./saxpy_multi_device2`
etc.

If you want to compile a specific example, type:

`make example_name` where example_name is a .cpp file (but without the .cpp extension).
