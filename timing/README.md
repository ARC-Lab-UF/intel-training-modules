# Introduction

These repository illustrates how to perform timing optimization (or timing closure) using Intel Quartus software. The provided examples are designed to work on the Intel DevCloud, but can also be performed by installing Quartus locally.

The [exercises](exercises/) folder includes simple circuits that explain the basics of timing optimization by providing unoptimized code that can be analyzed to identify timing bottlenecks, and then optimized using the presented techniques.

# Suggested Study Order

1. [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions) (Optional if using Quartus locally)
1. [Video: Background and Challenges](https://youtu.be/9Ld9Sr_JE9o), [Slides](timing_background.pptx)
    - Description: Provides an overview of necessary background material for understanding challenges of timing optimization.
1. [Video: Optimization Strategies](https://youtu.be/EZtRwBts9i8), [Slides](timing_opt.pptx)
    - Description: Describes different types of bottlenecks and common optimization strategies for eliminating those bottlenecks.
1. [Example: Add Tree](exercises/add_tree)
    - Description: Illustrates how to identify a logic-delay bottleneck with the Quartus Timing Analyzer, and then resolve that bottleneck using pipelining.
    - [Video: Quartus Timing Analyzer Overview and Add Tree Explanation](https://youtu.be/_rEisLZZIjI), [Slides](exercises/add_tree/analyzer_tutorial.pptx)
1. [Example: Timer](exercises/timer)
    - Description: Illustrates how to reduce LUT delays by shrinking logic inputs using constants.
    - [Video: Reducing LUT Delays (Timer Example)](https://youtu.be/CxkkZFIKGU4), [Slides](exercises/timer/timer.pptx)
1. [Example: Timer2](exercises/timer2)
    - Description: Improves upon the timer example to show how to further improve timing by simplifying logic.    

# [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions)

