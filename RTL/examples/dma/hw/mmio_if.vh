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

// Description:  This header provides an abstract MMIO interface that hides the
//               details of CCI-P.
//
//               The MMIO interface behaves similarly to the CCI-P 
//               functionality, except only supports single-cycle MMIO read 
//               responses, which eliminates the need for transaction IDs. 
//               MMIO writes behave identically to CCI-P.
//
//               When rd_en is asserted, the design must provide the
//               corresponding rd_data for the specified rd_addr one cycle 
//               later. For writes, when wr_en is asserted, the design must
//               store wr_data to the specified wr_addr in the same cycle.
//
//               All control signals are active high.

`ifndef MMIO_IF
`define MMIO_IF

interface mmio_if #(parameter int DATA_WIDTH, 
		    parameter int ADDR_WIDTH,
		    parameter int START_ADDR,
		    parameter int END_ADDR);   
   
   logic [DATA_WIDTH-1:0] rd_data;
   logic [ADDR_WIDTH-1:0] rd_addr;
   logic                  rd_en;
   
   logic [DATA_WIDTH-1:0] wr_data;
   logic [ADDR_WIDTH-1:0] wr_addr;
   logic                  wr_en;
   
   /*modport hal (
		input  rd_data,
		output rd_addr, rd_en, wr_data, wr_addr, wr_en
		);
   */
   modport user (
		 output rd_data,
		 input 	rd_addr, rd_en, wr_data, wr_addr, wr_en
		);
   
endinterface // mmio_if

`endif //  `ifndef MMIO_IF

   
