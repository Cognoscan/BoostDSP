--! @file basic_pkg.vhd
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

package basic_pkg is


--! Sin & Cos lookup table.
--! Outputs cos(2*pi*angle) and sin(2*pi*angle), where 0 <= angle < 1.
  component trig_table is
    port (
           clk    : in std_logic;
           rst    : in std_logic;
           angle  : in ufixed;
           sine   : out sfixed;
           cosine : out sfixed
         );
  end component;

  component mapper is
    generic (
    map_values_i : real_vector;
    map_values_q : real_vector
  );
  port (
         clk   : in std_logic;
         rst   : in std_logic;
         data  : in std_logic_vector;
         i_out : out sfixed;
         q_out : out sfixed
       );
  end component;

  component symbolizer is
    port (
           clk          : in std_logic; --! System clock
           rst          : in std_logic; --! System reset
           data_in      : in std_logic_vector; --! Incoming data
           busy         : out std_logic; --! Busy (cannot fetch data)
           data_valid   : in std_logic; --! Strobe when data_in valid
           fetch_symbol : in std_logic; --! System fetching next symbol
           symbol_out   : out std_logic_vector --! Outgoing symbol
         );
  end component;

end package;

package body basic_pkg is

end package body;
