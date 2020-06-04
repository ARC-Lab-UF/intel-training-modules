License Statement:  GPL Version 3
---------------------------------
Copyright (c) 2020 University of Florida

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

For the details of the GNU General Public License, see the included
gpl.txt file, or go to http://www.gnu.org/licenses/.

# Introduction

This example modifies the earlier [dma_loopback](../dma_loopback) example by modifying the afu.json file so that the AFU uses
the programmable user clock instead of the primary clock. The code also measures the clock frequency to verify that the 
requested clock is actually used on the PAC.

The clock frequency can be changed to any frequency by modifying this line in [hw/afu.son](hw/afu.json):
 
```
"clock-frequency-high": "auto-300.0",
```

This setting requests that Quartus compile the design with a 300 MHz clock. The "auto" prefix states to update the clock 
frequency if necessary if 300 MHz isn't possible. For full documentation of the JSON options, see the following:

https://www.intel.com/content/www/us/en/programmable/documentation/bfr1522087299048.html

However, note that many of the options discussed in that documentation are not currently supported in the OPAE installation
on the Intel DevCloud. At the time that this example was tested, the clock setting had to be "auto-\<float\>". 

# [Simulation Instructions](https://github.com/ARC-Lab-UF/intel-training-modules/blob/master/RTL/#simulation-instructions)
# [Synthesis Instructions](https://github.com/ARC-Lab-UF/intel-training-modules/tree/master/RTL#synthesis-instructions)
# [DevCloud Instructions](https://github.com/ARC-Lab-UF/intel-training-modules#devcloud-instructions)

 
