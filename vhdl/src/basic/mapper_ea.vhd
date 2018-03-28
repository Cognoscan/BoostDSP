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
    map_values_i : real_vector; --! I value vector to map data to
    map_values_q : real_vector  --! Q value vector to map data to
  );
  port (
    clk : in std_logic; --! System clock
    rst : in std_logic; --! System reset
    data : in std_logic_vector; --! Data vector to map to I & Q values
    i_out : out sfixed; --! I value output
    q_out : out sfixed  --! Q value output
  );
end entity;


architecture rtl of mapper is

  --! Generated Symbol Table for I values
  constant symbol_table_i : sfixed_vector :=
    to_sfixed_vector(map_values_i, i_out'high, i_out'low);
  --! Generated Symbol Table for Q values
  constant symbol_table_q : sfixed_vector := 
    to_sfixed_vector(map_values_q, q_out'high, q_out'low);

begin

  --! Uses the Symbol Tables as look-up tables to get the I & Q values 
  --! corresponding to a given data vector. The data vector is used as the index 
  --! to the look-up table, and is assumed to be an unsigned integer for this 
  --! purpose.
  mapping : process (clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        -- Output 0 on reset
        i_out <= to_sfixed(0.0, i_out);
        q_out <= to_sfixed(0.0, q_out);
      else
        -- Mapping of data
        i_out <= symbol_table_i(to_integer(unsigned(data)));
        q_out <= symbol_table_q(to_integer(unsigned(data)));
      end if;
    end if;
  end process;

end rtl;
