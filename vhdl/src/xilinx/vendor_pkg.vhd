--! @file vendor.vhd
--! @brief Functions optimized depending on part vendor
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-11-13
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
use ieee.numeric_std.all;

use work.fixed_pkg.all;

package vendor_pkg is

  --! Delay (in clock cycles) between input and output of 
  --! complex_multiply_sfixed and complex_multiply_signed.
  constant complex_multiply_delay : positive := 4;

  component complex_multiply_sfixed is
    port (
      clk : in std_logic; --! System clock
      rst : in std_logic; --! Reset signal
      a_r : in sfixed; --! Real component of A
      a_i : in sfixed; --! Imaginary component of A
      b_r : in sfixed; --! Real component of B
      b_i : in sfixed; --! Imaginary component of B
      c_r : out sfixed; --! Real component of C
      c_i : out sfixed  --! Imaginary component of C
    );
  end component;


end vendor_pkg;

package body vendor_pkg is

end package body;
