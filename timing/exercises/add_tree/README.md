# Introduction

This exercise illustrates how to identify a timing bottleneck using the Quartus timing analyzer, and how to resolve that bottleneck using pipelining. The example consists of a tree of adders whose inputs and output are registered. The provided files use a clock constraint of 200 MHz, which Quartus cannot achieve for the unoptimized code.

The unoptimized example is provided in the code/src/ directory, along with corresponding Quartus project files in the code/ directory. The solution is provided in the solution/ directory.

[This video](https://youtu.be/_rEisLZZIjI) explains the exercise and its corresponding solution.

# Instructions

1. In Quartus, open the add_tree.qpf project file in the code/ directory.
1. Look over the unoptimized code in code/src/.
1. Compile the project in Quartus.
1. Run the timing analyzer to identify the bottlneck.
1. Optimize the code to eliminate the bottleneck until the clock constraint is met.
