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
//#include <opae/mpf/shim_vtp.h>

#include "AFU.h"

using namespace std;
using namespace opae::fpga::types;
using namespace opae::fpga::bbb::mpf::types;

const unsigned AFU::PAGE_SIZES[] = {4096, 2097152, 1073741824};


AFU::AFU(handle::ptr_t fpga_handle) : fpga_(fpga_handle) {

  if (fpga_handle == nullptr)
    throw runtime_error("ERROR: AFU can't be constructed with a null handle.");

  mpf_ = mpf_handle::open(fpga_, 0, 0, 0);
  if (mpf_ == nullptr) {
    throw runtime_error("ERROR: MPF not available.");
  }

  if (!mpfVtpIsAvailable(*mpf_))
    throw runtime_error("ERROR: VTP not available in MPF.");
}


AFU::AFU(const char* uuid) : fpga_(requestAfu(uuid)) {
  
  mpf_ = mpf_handle::open(fpga_, 0, 0, 0);
  if (mpf_ == nullptr) {
    throw runtime_error("ERROR: MPF not available.");
  }

  if (!mpfVtpIsAvailable(*mpf_))
    throw runtime_error("ERROR: VTP not available in MPF.");
}


AFU::~AFU() {
  
  // Release all allocated buffers.
  // NOTE: Causes seg fault for unknown reason
  //       Try using mpfVtpReleaseBuffer instead.
  //for (shared_buffer::ptr_t i : buffers_) 
  //  i->release();

  // Clear the map of shared buffer pointers. This should trigger
  // the destructors and free the corresponding memory.
  // NOTE: mpf->close() seg faults unless the
  // buffer_map is cleared first.  
  buffer_map_.clear();

  mpf_->close();
  fpga_->close();
}


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


void AFU::reset() {

  fpga_->reset();
}


void AFU::write(uint64_t addr, uint64_t data) const {
  
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
  fpga_result status = fpgaWriteMMIO64(*fpga_, 0, (uint32_t) addr*4, data);    
  if (status != FPGA_OK) 
    throw status;
}


uint64_t AFU::read(uint64_t addr) const {
  
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
  fpga_result status = fpgaReadMMIO64(*fpga_, 0, addr*4, &data);
  if (status != FPGA_OK) 
    throw status;

  return data;
}


void AFU::free(volatile void* ptr) {
  
  // Casting away volatile qualifier to enable support for volatile and
  // non-volatile. Should be safe since we are just searching for the address 
  // of ptr and not modifying the contents of the array.
  auto it = buffer_map_.find((void*) ptr);
  if (it == buffer_map_.end()) {
    throw std::runtime_error("ERROR: AFU::free() called with pointer without shared buffer.");
  }
  
  buffer_map_.erase(it);      
};


opae::fpga::types::shared_buffer::ptr_t AFU::alloc(size_t bytes, PageOptions page_option, bool read_only) {
    
  if (page_option < PAGE_4KB || page_option > PAGE_1GB)
    throw std::runtime_error("ERROR: Invalid page size option.");
  
  opae::fpga::types::shared_buffer::ptr_t buf_handle;    
  unsigned page_size = this->PAGE_SIZES[page_option];
  
  // Quick way to round up to next multiple of page_size. This only works
  // for powers of 2, but the page_size will always be a power of 2.
  size_t page_aligned_bytes = (bytes + page_size - 1) & -page_size;
  
  // Allocate a virtually contiguous region of memory, just like you
  // would for any dynamic allocation in software.    
#ifdef MFP_OPAE_HAS_BUF_READ_ONLY
  buf_handle = opae::fpga::bbb::mpf::types::mpf_shared_buffer::allocate(mpf_, oage_aligned_bytes, read_only);
#else
  buf_handle = opae::fpga::bbb::mpf::types::mpf_shared_buffer::allocate(mpf_, page_aligned_bytes);
#endif
 
  // Save the buffer handle in the buffer_map_ using the address as the key.
  buffer_map_[(void*) buf_handle->c_type()] = buf_handle;
  return buf_handle;
}
