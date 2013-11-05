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

package rf_blocks_pkg is

  component dds is
    port (
           clk : in std_logic;
           rst : in std_logic;
           freq : in ufixed;
           i_out : out sfixed;
           q_out : out sfixed
         );
  end component dds;

end package;

package body rf_blocks_pkg is

end package body;


