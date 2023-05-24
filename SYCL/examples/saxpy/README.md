# SAXPY (Single-Precision A times X plus Y)

These programs demonstrate template parameter passing via lambda capture lists, in addition to common C++ problems. 

* [saxpy1.cpp](saxpy1.cpp)
  * Correct implementation of SAXPY demonstrating passing of scalars via lambda capture lists.
  * Tests random integer values between 0 and 100 for all inputs.
  
* [saxpy2.cpp](saxpy2.cpp)
  * Nearly identical code to the previous example, but tests random real numbers between 0 and 100.
  * This version reports errors due to a common C++ bug, related to equality comparison of floating-point numbers. 
  * MAIN POINT: Never compare floats for equality.

* [saxpy_correct.cpp](saxpy_correct.cpp)
  * Adds a function to replace equality comparison of float outputs to instead provide "sufficiently equal" comparisons.
    
## Devcloud instructions

Find suitable node (e.g. with gen9 gpu):  
`pbsnodes | grep -B 1 -A 8 "state = free" | grep -B 4 -A 4 gen9`

Login with interactive shell (replace the nodes section with a free node specified by the previous command):   
`qsub -I -l nodes=s001-n234:ppn=2`

Compile:   
`icpx -fsycl input_file -o output_file -Wall -O3`
   
Run:   
`./output_file`  
