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
  
  // Types, Constants

  // 4KB, 2MB, and 1GB pages
  // 2^12, 2^21, 2^30
  enum PageOptions {PAGE_4KB=0, PAGE_2MB, PAGE_1GB};
  static const unsigned PAGE_SIZES[];
  static const PageOptions DEFAULT_PAGE_OPTION = PageOptions::PAGE_2MB;
  static const unsigned CL_BYTES = 64;
  static const unsigned CL_BITS = 512;
 
  // Constructors, destrictors
  AFU(opae::fpga::types::handle::ptr_t);
  AFU(const char*);
  virtual ~AFU();
 
  // Methods
  static opae::fpga::types::handle::ptr_t requestAfu(const char* uuid); 
  virtual void reset();
  virtual void write(uint64_t addr, uint64_t data) const;
  virtual uint64_t read(uint64_t addr) const;  

  template <class T>
  T* malloc(size_t elements, PageOptions page_option=DEFAULT_PAGE_OPTION, bool read_only=false) {   
    
    opae::fpga::types::shared_buffer::ptr_t buf_handle;
    buf_handle = alloc(elements*sizeof(T), page_option, read_only);  
    return reinterpret_cast<T*>(buf_handle->c_type()); 
  }

  template <class T>
  T* mallocNonvolatile(size_t elements, PageOptions page_option=DEFAULT_PAGE_OPTION, bool read_only=false) {   
         
    opae::fpga::types::shared_buffer::ptr_t buf_handle;
    buf_handle = alloc(elements*sizeof(T), page_option, read_only); 

    // Allow for a dangerous const_cast that eliminates the volatility of the
    // allocated data. This could potentially cause errors since the compiler
    // may perform optimizations without the knowledge of the FPGA. However,
    // removing the volatility allows the returned pointer to be passed to
    // functions that do not have volatile parameters (e.g., libraries).
    return reinterpret_cast<T*>(const_cast<uint8_t*>(buf_handle->c_type())); 
  }  
  
  void free(volatile void *ptr);

protected: 

  // Members
  std::map<void*, opae::fpga::types::shared_buffer::ptr_t> buffer_map_;
  opae::fpga::types::handle::ptr_t fpga_;
  opae::fpga::bbb::mpf::types::mpf_handle::ptr_t mpf_;

  // Methods
  opae::fpga::types::shared_buffer::ptr_t alloc(size_t bytes, PageOptions page_option, bool read_only);
};

#endif
