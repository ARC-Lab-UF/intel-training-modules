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

`ifndef __PIPE_PKG__
`define __PIPE_PKG__

package pipe_pkg;

   // Latencies of the floating-point cores. Change these if you modify the
   // cores from the IP library.
   localparam int MULT_LATENCY = 3;
   localparam int ADD_LATENCY  = 3;

   // Normally I would make this a function of the number of inputs, but since
   // the pipeline is hardcoded for a specific number of inputs in this example,
   // this will suffice.
   // The *3 is because of the 3 levels of adders. The +1 is for the 
   // registered inputs.    
   localparam int PIPE_LATENCY = MULT_LATENCY + ADD_LATENCY*3 + 1;

endpackage

`endif
