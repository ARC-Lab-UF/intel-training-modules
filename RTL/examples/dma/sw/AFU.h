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

#ifndef __AFU_H__
#define __AFU_H__

#include <list>
#include <opae/cxx/core/handle.h>
#include <opae/cxx/core/shared_buffer.h>
#include <opae/mpf/cxx/mpf_handle.h>
#include <opae/mpf/cxx/mpf_shared_buffer.h>

class AFU {

public:
  AFU(opae::fpga::types::handle::ptr_t);
  AFU(const char*);
  virtual ~AFU();

  static opae::fpga::types::handle::ptr_t requestAfu(const char* uuid); 

  template <class T>
  T* malloc(size_t bytes, bool read_only=false, bool is_volatile=true) {
    
    opae::fpga::types::shared_buffer::ptr_t buf_handle;
    //opae::fpga::bbb::mpf::types::mpf_shared_buffer::ptr_t buf_handle;
    
    //size_t aligned_bytes = bytes % getpagesize() == 0 ? bytes : 

    // Allocate a virtually contiguous region of memory, just like you
    // would for any dynamic allocation in software.    
#ifdef MFP_OPAE_HAS_BUF_READ_ONLY
    buf_handle = opae::fpga::bbb::mpf::types::mpf_shared_buffer::allocate(mpf, bytes*sizeof(T), read_only);
#else
    buf_handle = opae::fpga::bbb::mpf::types::mpf_shared_buffer::allocate(mpf, bytes*sizeof(T));
#endif
    
    buffers.push_back(buf_handle);

    // Allow for a dangerous const_cast that eliminates the volatility of the
    // allocated data. This could potentially cause errors since the compiler
    // may perform optimizations without the knowledge of the FPGA. However,
    // removing the volatility allows the returned pointer to be passed to
    // functions that do not have volatile parameters (e.g., libraries).
    if (is_volatile)
      return reinterpret_cast<T*>(buf_handle->c_type());    
    else
      return reinterpret_cast<T*>(const_cast<uint8_t*>(buf_handle->c_type()));
  }

//volatile void* malloc (size_t bytes,
//			   bool read_only=false);

  virtual void reset();
  virtual void write(uint64_t addr, uint64_t data);
  virtual uint64_t read(uint64_t addr);
    
protected: 

  std::list<opae::fpga::types::shared_buffer::ptr_t> buffers;
  opae::fpga::types::handle::ptr_t fpga;
  opae::fpga::bbb::mpf::types::mpf_handle::ptr_t mpf;
};

#endif
