--! @file mapper_ea.vhd
--! @brief Maps data vector to I & Q sample levels
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

--! Maps a data vector to I & Q amplitudes (a.k.a. a symbol). This mapper is 
--! fixed, meaning that the symbol mapping table cannot be changed while the 
--! system is running. The mapper is essentially a lookup table; data is 
--! considered to be an unsigned integer used to look up I & Q values from the
--! map_values_i and map_values_q. Note that map_values_i and map_values_q are 
--! converted to fixed point values of the same size as i_out and q_out.
entity mapper is
  generic (
    map_values_i : real_vector;
    map_values_q : real_vector
  );
  port (
    clk : in std_logic;
    rst : in std_logic;
    data : in std_logic_vector;
    i_out : out sfixed;
    q_out : out sfixed
  );
end entity;


architecture rtl of mapper is

  constant symbol_table_i : sfixed_vector :=
    to_sfixed_vector(map_values_i, i_out'high, i_out'low);
  constant symbol_table_q : sfixed_vector := 
    to_sfixed_vector(map_values_q, q_out'high, q_out'low);

begin

  mapping : process (clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        i_out <= to_sfixed(0.0, i_out);
        q_out <= to_sfixed(0.0, q_out);
      else
        i_out <= symbol_table_i(to_integer(unsigned(data)));
        q_out <= symbol_table_q(to_integer(unsigned(data)));
      end if;
    end if;
  end process;

end rtl;
