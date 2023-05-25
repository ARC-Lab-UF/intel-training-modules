# Matrix Add

These example demonstrate a matrix add:
            
    for (int i=0; i < NUM_ROWS; i++)
        for (int j=0; j < NUM_COLS; j++)
            out[i][j] = in1[i][j] + in2[i][j];
        

While a matrix add by itself has a simple kernel, these examples are intended to illustrate many common problems when working with multi-dimensional data.

IMPORTANT: Make sure to read through all comments for an explanation of the code.

1. [matrix_add_bad.cpp](matrix_add_bad.cpp) 
    - Demonstrates a common problem where buffered multiple-dimensional data structures are not stored in memory sequentially.
    - NOTE: Intentionally does not compile, and is excluded from the make all target. You can manually compile it with: 
     
        `make matrix_add_bad` 
    - IMPORTANT: All host data that will be used by the device must be stored sequentially in memory.    
1.  [matrix_add_static1.cpp](matrix_add_static1.cpp)
    - Demonstrates ony one solution for statically sized data (i.e., the size is a compile-time constant)
    - Fixes the previous example by using an std::array of std:array, which is guaranteed to be stored sequentially.
1.  [matrix_add_static2.cpp](matrix_add_static2.cpp)
    - Demonstrates another solution for statically sized data using C-style multi-dimensional arrays.    
1.  [matrix_add_dynamic1.cpp](matrix_add_dynamic1.cpp)
    - Demonstrates another solution for dynamically sized data (i.e., size determined at run-time)
    - Uses a common strategy of storing multi-dimensional data in a dynamically allocated 1D array with manual indexing computations.    
1.  [matrix_add_dynamic2.cpp](matrix_add_dynamic2.cpp)
    - Similar to previous example, but uses vectors instead of manually allocated memory,
    - This is slightly safer, but still requires manual indexing computations throughout the code.
1.  [matrix_add_dynamic3.cpp](matrix_add_dynamic3.cpp)
    - Simplifies the previous dyanmic examples with a custom Matrix class that internally stores data sequentially, while overloading the [] operator to hide the manual indexing computations.
    - I would strongly recommend this type of approach for multi-dimensional data, where you have a class that presents the data in multiple dimensional while internally storing it sequentially.
    
## Compilation and Execution Instructions

First, make sure you have logged on to a suitable node [(see here)](../../../SYCL#devcloud-usage-instructions).

To compile all examples, simply type:

`make`

This will generate an executable for each example that you can run with:

`./matrix_add_static1`
`./matrix_add_static2`
`./matrix_add_dynamic1`
`./matrix_add_dynamic2`
`./matrix_add_dynamic3`
etc.

If you want to compile a specific example, type:

`make example_name` where example_name is a .cpp file (but without the .cpp extension).
