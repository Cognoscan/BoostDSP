--! @file comm_systems_pkg.vhd
--! @brief Package containing all basic communication systems in BoostDSP
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-11-06
--! @copyright
--! Copyright 2013 Richard Scott Teal, Jr.
--! 
--! Licensed under the Apache License, Version 2.0 (the "License"); you may not 
--! use this file except in compliance with the License. You may obtain a copy 
--! of the License at
--! 
--! http://www.apache.org/licenses/LICENSE-2.0
--! 
--! Unless required by applicable law or agreed to in writing, software 
--! distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
--! WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
--! License for the specific language governing permissions and limitations
--! under the License.

--! Standard IEEE library
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

use work.fixed_pkg.all;

package comm_systems_pkg is

  component simple_tx is
  generic (
    INCLUDE_DDS  : boolean;
    MAP_VALUES_I : real_vector;
    MAP_VALUES_Q : real_vector
  ); 
  port (
           clk               : in std_logic; --! System clock
           rst               : in std_logic; --! System reset
           frame_size        : in unsigned; --! Size of frame to transmit
           clks_per_symbol   : in unsigned; --! Clock cycles per symbol transmitted
           start             : in std_logic; --! Strobe high to start transmitting.
           abort             : in std_logic; --! Strobe high to abort transmitting.
           frame_tx_complete : out std_logic; --! High when not transmitting.
           buffer_addr       : in std_logic_vector; --! Address to read/write to.
           buffer_we         : in std_logic; --! High when write, low when read.
           buffer_write_data : in std_logic_vector; --! Data to write.
           buffer_read_data  : out std_logic_vector; --! Data read from address.
           buffer_strobe     : in std_logic; --! Strobe high to cycle bus.
           buffer_done       : out std_logic; --! Strobe high when read/write complete.
           freq              : in ufixed; --! Only needed if DDS is used
           i_out             : out sfixed; --! In-phase data
           q_out             : out sfixed --! Quadrature-phase data
       );
  end component;

end package;

package body comm_systems_pkg is

end package body;


