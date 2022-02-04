# Introduction

These repository illustrates how to perform timing optimization (or timing closure) using Intel Quartus software. The provided examples are designed to work on the Intel DevCloud, but can also be performed by installing Quartus locally.

The [exercises](exercises/) folder includes simple circuits that explain the basics of timing optimization by providing the reader with unoptimized code that they can analyze to identify timing bottlenecks, and then optimize using the presented techniques. Each exercise includes a solution for reference. The [examples](examples/) folder demonstrates timing optimization examples without corresponding exercises.

# Suggested Study Order

1. [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions) (Optional if using Quartus locally)
1. [Video: Background and Challenges](https://youtu.be/9Ld9Sr_JE9o), [Slides](timing_background.pptx)
    - Description: Provides an overview of necessary background material for understanding challenges of timing optimization.
1. [Video: Optimization Strategies](https://youtu.be/EZtRwBts9i8), [Slides](timing_opt.pptx)
    - Description: Describes different types of bottlenecks and common optimization strategies for eliminating those bottlenecks.
1. [Exercise: Add Tree](exercises/add_tree)
    - Description: Illustrates how to identify a logic-delay bottleneck with the Quartus Timing Analyzer, and then resolve that bottleneck using pipelining.
    - [Video: Quartus Timing Analyzer Overview and Add Tree Explanation](https://youtu.be/_rEisLZZIjI), [Slides](exercises/add_tree/analyzer_tutorial.pptx)
1. [Exercise: Timer](exercises/timer)
    - Description: Illustrates how to reduce LUT delays by shrinking logic inputs using constants.
    - [Video: Reducing LUT Delays (Timer Example)](https://youtu.be/CxkkZFIKGU4), [Slides](exercises/timer/timer.pptx)
1. [Exercise: Timer2](exercises/timer2)
    - Description: Improves upon the timer example to show how to further improve timing by simplifying logic.   
1. [Example: Register Duplication](examples/register_duplication)
    - Description: Demonstrates how to reduce fanout bottlenecks resulting from high register fanout via register duplication. 
1. [Example: Reset Reduction](examples/reset_reduction)
    - Description: Demonstrates how high fanout reset signals can create timing bottlenecks, and that be removing resets from registers that don't need them is a simple way to improve clock frequencies.
1. [Example: Reset Tree](examples/reset_tree)
    - Description: Demonstrates an advanced technique for distributing a reset with a register tree to reduce maximum reset fanout. 
1. [Example: Multicycle Path](examples/multicycle_path)
    - Description: Demonstrates how to use multicycle paths to improve timing. 
1. [Example: Count](examples/count)
    - Description: Demonstrates how to reduce resources and improve timing for multiple conditional add/sub operations.
1. [Example: 3-input Adder](examples/adder_3input) (REQUIRES QUARTUS PRIME PRO)
    - Description: Demonstrates how 10-series FPGAs can implement some 3-input adders with the same number of resources as 2-input adders.
1. [Example: Add/Sub](examples/add_sub) (REQUIRES QUARTUS PRIME PRO)
    - Description: Demonstrates resource and timing tradeoffs between different adder/subtractor implementations.

# [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions)

