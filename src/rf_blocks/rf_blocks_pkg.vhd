--! @file rf_blocks_pkg.vhd
--! @brief Package containing all basic elements in BoostDSP
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-11-04
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
use work.util_pkg.all;

package rf_blocks_pkg is

  --! Direct Digital Synthesizer. Generates 2 sinusoidal waves 90 degrees out of 
  --! phase with each other. Frequency is determined by freq, which should be 
  --! some value between 0 and 1. Realistically, this value will only be between 
  --! 0 and 0.5, where i_out[n] = cos(2*pi*freq*n) and q_out[n] 
  --! = sin(2*pi*freq*n).
  component dds is
    port (
           clk   : in std_logic; --! Clock line
           rst   : in std_logic; --! Reset line
           freq  : in ufixed;    --! Frequency input
           phase : in ufixed;    --! Additional phase offset
           i_out : out sfixed;   --! I Sinusoidal output
           q_out : out sfixed    --! Q Sinusoidal output
         );
  end component dds;

  --! Polyphase Direct Digital Synthesizer. For each phase channel, generates 
  --! 2 sinusoidal waves 90 degrees out of phase with each other. Frequency is 
  --! determined by freq, which should be some value between 0 and 1. 
  component poly_dds is
  port (
    clk   : in std_logic;      --! Clock line
    rst   : in std_logic;      --! Reset line
    freq  : in ufixed;         --! Frequency input
    phase : in ufixed;         --! Additional phase offset
    i_out : out sfixed_vector; --! I Sinusoidal output vector
    q_out : out sfixed_vector  --! Q Sinusoidal output vector
  );
  end component;

  component frame_tx is
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
           symbol_out        : out std_logic_vector --! Symbol output
         );
  end component;

end package;

package body rf_blocks_pkg is

end package body;


