# Accumulation

This example demonstrates how to parallelize accumaltion, while also showing numerous common race conditions and optimization strategies.
This examples illustrates the most common techniques used many applications and should be studied in detail.

The psuedo-code for accumulation is:



    int accum = 0;
    for (int i=0; i < VECTOR_SIZE; i++)
    	accum += x[i];

Despite looking conceptually simple, this is actually by far the hardest example we have seen so far. Accumulation is an example of a "reduction"
operation, that takes a large number of inputs and "reduces" them (in this case by adding) into a single input.

Parallel reduction code can look very intimidating without an understaning of the basic strategies. It is highly recommended that you read
the provided slides before looking over the code. These slides visualize what is going on in each presented strategy.

IMPORTANT: Make sure to read through all comments for an explanation of the code.

1. [accum_strategy1_bad.cpp](accum_strategy1_bad.cpp)
   - Implements Strategy 1 from the slides.
   - This is a commonly attempted incorrect approach. However, we will leverage parts of it in later strategies/
   - Test this example with a small input size (e.g. 100). Note that it succeeds (or at least likely does)
   - Test it again with a larger input size (anything over 1000), and it should fail. This is a common problem.
   - KEY POINT: Just because you aren't getting errors, doesn't mean your code is correct.
1. [accum_strategy2_bad.cpp](accum_strategy2_bad.cpp)
   - Implements Strategy 2 from the slides.
   - Tries to address the race condition from the previous example, but doesn't fully solve the problem.
   - Test this example with an input size of 1000. That size failed for the previous example, but now passes. This does not mean the code works.
   - Test it again with a large input size (anything over 10000), and it should fail.
1. [accum_strategy3_1.cpp](accum_strategy3_1.cpp)
   - Implements Strategy 3 from the slides.
   - Presents a correct, but terribly slow implementation.
   - Test this with an input size of 1000000000 (1 billion), and it should take over 80s.
1. [accum_strategy3_2.cpp](accum_strategy3_2.cpp)
   - Optimizes the previous example of Strategy 3 by minimizing data transfers.
   - Test this for 1B inputs and it should take around 13.7s.
1. [accum_strategy3_3.cpp](accum_strategy3_3.cpp)
   - Further optimizes the previous Strategy 3 examples by minimizing the data copied from the output vector.
   - Test this for 1B inputs and it should take around 6.1s.
1. [accum_strategy3_4.cpp](accum_strategy3_4.cpp)
   - Further optimizes the previous Strategy 3 examples by optimizing the number of work-items.
   - Test this for 1B inputs and it should take around 4.5s.
1. [accum_strategy4_1.cpp](accum_strategy4_1.cpp)
   - Demonstrates Strategy 4, which avoids copying the output vector back to the input vector.
   - Test this for 1B inputs and it should take around 2.0s.
1. [accum_strategy4_2.cpp](accum_strategy4_2.cpp)
   - Demonstrates an alternative implementation for Strategy 4 that has more transparent code, but is slower.
   - Test this for 1B inputs and it should take around 3.7s.
1. [accum_strategy5.cpp](accum_strategy5.cpp)
   - Implements Strategy 5, which avoids a separate output vector by adding a stride to the array indexing.
   - Test this for 1B inputs and it should take around 40s.
   - This Strateg by itself is terribly slow, but is useful when integrated with the next strategy.
1. [accum_strategy6_1_bad.cpp](accum_strategy6_1_bad.cpp)
   - Implements Strategy 6, which is generally the ideal approach for reduction.
   - Demonstrates work-groups, local memory, and synchronization within work-groups.
   - Test this for 1B inputs and it should take around 2.4s.
   - IMPORTANT: Despite likely providing the correct output, there is a subtle race condition in this code, making it incorrect.
1. [accum_strategy6_2.cpp](accum_strategy6_2.cpp)
   - Fixes the previous implementation of Strategy 6 by adding separate input and output vectors.
   - Test this for 1B inputs and it should take around 2.0s.
1. [accum_strategy6_3.cpp](accum_strategy6_3.cpp)
   - Optimizes the previous implementation of Strategy 6 by minimizing data transfers.
   - Test this for 1B inputs and it should take around 1.98s.
   - IMPORTANT: This implementation can be used as a template for any reduction operation.

    
## Compilation and Execution Instructions

First, make sure you have logged on to a suitable node [(see here)](../../../SYCL#devcloud-usage-instructions).

To compile all examples, simply type:

`make`

This will generate an executable for each example that you can run with:

`./accum_strategy1_bad`
`./accum_strategy2_bad`
`./accum_strategy3_1`
`./accum_strategy3_2`
etc.

If you want to compile a specific example, type:

`make example_name` where example_name is a .cpp file (but without the .cpp extension).
