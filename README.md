This respository provides training modules explaining how to design applications for the Intel Platform Acceleration Card (PAC).

Currently the repository includes explanations for writing RTL code, combined with C++, but will eventually be expanded to explain other design-entry methods including OpenCL, DPC++, OneAPI, and OpenVINO.

# Training Modules

Here is an [overview of the Intel PAC](https://www.youtube.com/watch?v=HatHuLtZ5-0&), along with the [corresponding slides](intel_pac_overview.pptx).

1. [Register-transfer-level (RTL) training](RTL/)
    - Description: Explanation for how to develop RTL code for the Intel PAC
1. [FPGA timing optimization](timing/)
    - Description: Explanation for how to perform FPGA timing optimization.
     
# DevCloud Instructions

- [Explanation for how to register, connect, and use the DevCloud for these exercises](https://github.com/intel/FPGA-Devcloud).

- [Quickstart Guide for Arria 10 PAC](https://github.com/intel/FPGA-Devcloud/tree/master/main/QuickStartGuides/RTL_AFU_Program_PAC_Quickstart/Arria10)

- To clone this repository on the DevCloud, login after using the above instructions and then run: 
    
```
    $ git clone https://github.com/ARC-Lab-UF/intel-training-modules.git   
```
    
