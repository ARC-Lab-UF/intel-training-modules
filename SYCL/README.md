# Introduction

This repository provides a tutorial on SYCL and DPC++. The provided examples are designed to work on the Intel DevCloud, but can also be performed by installing the necessary tools locally.

The tutorial assumes you have some experience with C++, but includes an overview of recent constructs that are leveraged within SYCL (e.g, lambas).

<!---The [exercises](exercises/) folder includes simple circuits that explain the basics of timing optimization by providing the reader with unoptimized code that they can analyze to identify timing bottlenecks, and then optimize using the presented techniques. Each exercise includes a solution for reference. The [examples](examples/) folder demonstrates timing optimization examples without corresponding exercises.--->

# DevCloud Usage Instructions

This tutorial assumes you already have a DevCloud account. To execute the included examples, when you log on to the DevCloud, you first need to find a suitable node. For most examples, this can be done in the following way:

`qsub -I -l nodes=1:gen9:ppn=2`

In general, you can search for available nodes with various properties (e.g., Gen9 CPU) using the following:

`pbsnodes | grep -B 1 -A 8 "state = free" | grep -B 4 -A 4 gen9`

This provides a list of available nodes. You can then manually log into one using the following (using node s001-n234 as an example):

`qsub -I -l nodes=s001-n234:ppn=2`

Once logged onto a node, you can execute these examples by following the example-specific compilation instructions. For custom compilations, you can use the following:

`icpx -fsycl input_file -o output_file -Wall -O3`

# Suggested Study Order

1. [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions) (Optional if using SYCL/DPC++ locally)
1. [C++ Crash Course for SYCL](cpp_crash_course.pptx)
    - Description: Provides an overview of C++ constructs and practices that are leveraged within SYCL.
    - Without this background, SYCL syntax can look very intimidating. Even if you are familiar with C++, this overview is recommended as a refresher for the modern constructs.
1. [Heterogeneous Parallel Programming and OpenCL Overvivew](opencl_overview.pptx)
    - Description: Provides overview of fundamental concepts of heterogeneous parallel programming, including OpenCL
    - Provides necessary background on OpenCL concepts that are leveraged within SYCL (e.g, platform model, kernels, work-items, work-groups, NDRange, etc.).
1. [Example: Vector Add](examples/vector_add)
    - Description: Vector addition example that introduces basic SYCL concepts (queues, kernels, buffers, accessors, device vs. host code). 
    - Demonstrates common mistakes with buffers and accessors.
    - Demonstrates basic exception handling.
1. [Example: SAXPY](examples/saxpy)
    - Description: Single-precision A times X plus Y, where A is a scalar, and X and Y are vectors. This is a common linear-algebra operation.
    - Demonstrates scalar parameter passing via lambda capture lists.
    - Demonstrates common C++ bugs with floating-point comparisons, and corresponding solutions.
1. [Example: Multi-Kernel/Device SAXPY](examples/multi_kernel_saxpy)
    - Description: Extends the SAXPY example to execute on multiple kernels, and then shows how to execute each kernel on a different device.
    - Demonstrates how to communicate and synchronize between multiple kernels, how to map different kernels onto different devices, and different parallelization strategies.
    - NOTE: using multiple kernels for SAXPY is largely artificial and intended for illustration only. The demonstrated concepts are intended to be applied to larger examples.
1. [Example: Accumulation](examples/accum)
    - Description: Accumulates the values from a provided vector/array.
    - Demonstrates 6 different accumulation strategies.
    - Demonstrates common synchronization mistakes and race condidtions.
    - Demonstrates use of work-groups and local memory.
    - Final example demonstrates basics you should know for most realistic heterogeneous parallel programs.
1. [Example: Matrix Add](examples/matrix_add)
    - Description: addition of two matrices. 
    - Demonstrates problematic issues when working with multi-dimensional data.
    - Compares several strategies when using statically and dynamically sized matrices.    
1. [Example: USM](examples/usm)
    - Description: Compares SYCL two communication methods: Unified Shared Memory (USM) and Buffers/Allocators.
    - Analyzes tradeoffs of both approaches
1. [Example: FPGA Introduction](fpga_intro)
    - Description: Demonstrates how to specialize the earlier SAXPY example for field-programmable gate arrays (FPGAs).

<!---
## Future Examples:
1. [Example: Profiling]()
    - Description: Demonstrates how to profile and benchmark examples using C++ and built-in SYCL constructs.
1. [Example: Advanced FPGA Examples]()
    - Description:TODO.
1. [Example: Avdvanced Multi-Device Examples]()
    - Description:TODO.   
--->

# [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions)

