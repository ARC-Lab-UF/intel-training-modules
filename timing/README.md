# Introduction

These examples illustrate how to perform timing optimization (or timing closure) using Intel Quartus software. The examples are designed to work on the Intel DevCloud, but can also be performed locally by installing Quartus.

The [examples](examples/) folder includes simple examples that explain the basics of timing optimization by identifying different types of timing bottlenecks and then resolving them. 

# Suggested Study Order

1. [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions) (Optional if using Quartus locally)
1. [Video: Background and Challenges](https://youtu.be/Tj2TseM7pr8), [Slides]()
    - Description: Provides an overview of necessary background material for understanding challenges of timing optimization.
1. [Video: Optimization Strategies](https://youtu.be/EZtRwBts9i8), [Slides]()
    - Description: Describes different types of bottlenecks and common optimization strategies for eliminating those bottlenecks.
1. [Example: Add Tree](examples/add_tree)
    - Description: Illustrates how to identify a logic-delay bottleneck with the Quartus Timing Analyzer, and then resolve that bottleneck using pipelining.
    - [Video: Quartus Timing Analyzer Overview and Add Tree Explanation](https://youtu.be/4D8miQFEZyg), [Slides (TBD)]()
1. [Example: Timer](examples/add_tree)
    - Description: Illustrates how to reduce LUT delays by shrinking logic inputs using constants.
    - [Video: Reducing LUT Delays (Timer Example)](https://youtu.be/4D8miQFEZyg), [Slides (TBD)]()

# [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions)

