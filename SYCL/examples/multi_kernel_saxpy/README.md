# Using Multiple Kernels and Devices for SAXPY

These code examples show to divide a computation into multiple kernels to create task-level parallelism that can then be executed using various parallelization strategies, including on multiple devices.

The first two examples trasnsform the original code:

    for (int i=0; i < VECTOR_SIZE; i++)
        z[i] = a * x[i] + y[i];
        
into two separate kernels:

    for (int i=0; i < VECTOR_SIZE; i++)
        temp[i] = a * x[i];
        
and

    for (int i=0; i < VECTOR_SIZE; i++)
        z[i] = temp[i] + y[i];

For a simple example like SAXPY, this separation is artificial. In fact, a common optimization is to "fuse" (i.e., combine) multiple fine-grained kernels to reduce communication overhead.
We use SAXPY simply for ease of explanation, but multiple kernels stragies are important for larger applications and when using multiple devices.

In addition to showing multiple kernels on multiple devices, we also demonstrate a parallelization strategy where we execute the same kernel on different devices by partitioning the input,
which is sometimes referred to as a "scatter." To do a scatter effectively, each device must receive a number of inputs that ideally makes all devices take the same time, which is referred to
as "load balancing." In this example, we don't load balance the execution and instead demonstrate how to implement a scatter. Load balancing would require profiling each available device
to determine execution times for different inputs sizes.

IMPORTANT: Make sure to read through all comments for an explanation of the code.

1. [saxpy_multi_kernel.cpp](saxpy_multi_kernel.cpp) 
    - Divides the original SAXPY kernel into the two smaller kernels shown above, and executes them on the same device.
1.  [saxpy_multi_device.cpp](saxpy_multi_device.cpp)
    - Similar code as the previous example, but maps each kernel onto a different device (a CPU and GPU).    
1. [saxpy_scatter.cpp](saxpy_scatter.cpp)
    - Demonstrated the "scatter" parallelization strategy where we execute the same kernel on different devices with different sections of the input.
    
## Compilation and Execution Instructions

First, make sure you have logged on to a suitable node [(see here)](../../../SYCL#devcloud-usage-instructions).

To compile all examples, simply type:

`make`

This will generate an executable for each example that you can run with:

`./saxpy_multi_kernel`
`./saxpy_multi_device`
`./saxpy_scatter`
etc.

If you want to compile a specific example, type:

`make example_name` where example_name is a .cpp file (but without the .cpp extension).
