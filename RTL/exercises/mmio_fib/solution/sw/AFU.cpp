// Copyright (c) 2020 University of Florida
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Greg Stitt
// University of Florida

#include <opae/mmio.h>
#include <opae/properties.h>

#include "AFU.h"

using namespace std;
using namespace opae::fpga::types;


handle::ptr_t AFU::requestAfu(const char* uuid) {

  // Create a filter to find an FPGA accelerator with the requested AFU uuid.
  properties::ptr_t filter = properties::get();
  filter->guid.parse(uuid);
  filter->type = FPGA_ACCELERATOR;
  
  // Find all potential accelerators with the requested AFU UUID.
  vector<token::ptr_t> accelerators = token::enumerate({filter});
  if (accelerators.size() == 0) {    
    throw FPGA_NOT_FOUND;
  }
  
  // From candidates, find accelerator that isn't busy. 
  for (token::ptr_t a : accelerators) { 
    try {
      // Return a handle to this accelerator since it isn't busy.
      return handle::open(a, 0);
    }
    catch (const opae::fpga::types::busy &e) {
      // open() throws a busy exception when the requested accelerator is in 
      // use. In this case, we want to do nothing, so just catch the exception
      // and try the next accelerator.
    }
  }
  
  // All accelerators were busy, so throw corresponding exception.
  throw FPGA_BUSY;
}


AFU::AFU(handle::ptr_t fpga_handle) : fpga(fpga_handle) {

  if (fpga_handle == nullptr)
    throw runtime_error("ERROR: AFU can't be constructed with a null handle.");
}


AFU::AFU(const char* uuid) : fpga(requestAfu(uuid)) {
  
}


AFU::~AFU() {

  fpga->close();
}


void AFU::reset() {

  fpga->reset();
}


void AFU::write(uint64_t addr, uint64_t data) {
  
  // This AFU wrapper class only supports 64-bit MMIO transfers, which requires 
  // the 32-bit word address to be even.
  if (addr % 2 == 1) {
    throw runtime_error("ERROR: AFU::write requires even addresses due to 64-bit MMIO transfers");
  }

  // Write data to the 32-bit word address addr in the FPGA's MMIO address 
  // space.
  // The code multiples addr by 4 because fpgaWriteMMIO64 requires
  // a byte address. The address we specified in the RTL code was for 32-bit
  // words, so we need to multiply the word address by 4.
  fpga_result status = fpgaWriteMMIO64(*fpga, 0, (uint32_t) addr*4, data);    
  if (status != FPGA_OK) 
    throw status;
}


uint64_t AFU::read(uint64_t addr) {
  
  // This AFU wrapper class only supports 64-bit MMIO transfers, which requires 
  // the 32-bit word address to be even.
  if (addr % 2 == 1) {
    throw runtime_error("ERROR AFU::read requires even addresses due to 64-bit MMIO transfers");
  }
  
  // Read from 32-bit word address addr in the FPGA's MMIO address space and 
  // store the result in data.
  // The code multiples addr by 4 because fpgaReadMMIO64 requires
  // a byte address. The address we specified in the RTL code was for 32-bit
  // words, so we need to multiply the word address by 4.
  uint64_t data;  
  fpga_result status = fpgaReadMMIO64(*fpga, 0, addr*4, &data);
  if (status != FPGA_OK) 
    throw status;

  return data;
}
