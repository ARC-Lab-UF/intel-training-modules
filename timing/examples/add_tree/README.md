# Introduction

This exercise illustrates how to identify a timing bottleneck using the Quartus
timing analyzer, and how to resolve that bottleneck using pipelining.

The unoptimized code is provided in the code/ directory, along with a corresponding Quartus project files. The solution is provided in the solution/ directory.

[This video](https://youtu.be/HXS3JCx55Q4) explains the exercise and its corresponding solution.

# Instructions

1. Open the add_tree.qpf Quartus project in the code/ directory.
1. Look over the unoptimized code in code/src/add_tree.sv.
1. Compile the project in Quartus.
1. Run the timing analyzer to identify the bottlneck
1. Optimize the code to eliminate the bottleneck until the clock constraint is met.
