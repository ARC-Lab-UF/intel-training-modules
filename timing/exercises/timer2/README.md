# Introduction

This exercise extends the previous timer example by now requiring a clock constraint of 250 MHz. The solution to the original timer is now provided as the unoptimized code that
must be further improved to run at 250 MHz.

The unoptimized example code is provided in the ../timer/solution/src/ directory, along with corresponding Quartus project files in the code/ directory. The solution is provided in the solution/ directory.

# Instructions

1. In Quartus, open the timer.qpf project file in the code/ directory.
1. Compile the project in Quartus.
1. Run the timing analyzer to identify the bottlneck.
1. Optimize the code to eliminate the bottleneck until the clock constraint is met.
