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

#include <opae/cxx/core/handle.h>

class AFU {

public:
  AFU(opae::fpga::types::handle::ptr_t);
  AFU(const char*);
  virtual ~AFU();

  static opae::fpga::types::handle::ptr_t requestAfu(const char* uuid);  

  virtual void reset();
  virtual void write(uint64_t addr, uint64_t data);
  virtual uint64_t read(uint64_t addr);
    
protected: 

  opae::fpga::types::handle::ptr_t fpga;
};

#endif
