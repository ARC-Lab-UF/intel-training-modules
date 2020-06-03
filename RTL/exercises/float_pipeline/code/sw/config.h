// Greg Stitt
// University of Florida

#ifndef __CONFIG_H__
#define __CONFIG_H__

//=============================================================
// Configuration settings

const float ACCEPTABLE_PERCENT_ERROR = 0.00001;  

// When simulating, there is a loop that does nothing but wait for the DMA 
// to finish. This constant "polling" is very inefficient and can slow down 
// the CPU. Defining this flag causes the processor to periodically sleep
// during this polling.
// NOTE: For execution on the FPGA, comment this out.
#define SLEEP_WHILE_WAITING

// The number of milliseconds to sleep when SLEEP_WHILE_WAITING is defined.
const unsigned SLEEP_MS = 10;


//=============================================================
// AFU MMIO Addresses

enum MmioAddr {
  
  MMIO_GO=0x0050,
  MMIO_RD_ADDR=0x0052,
  MMIO_WR_ADDR=0x0054,
  MMIO_SIZE=0x0056,
  MMIO_DONE=0x0058
};



#endif
