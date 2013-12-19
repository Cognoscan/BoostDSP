--! @file strobed_trig_table_ea.vhd
--! @brief data strobed sin/cos lookup table generator
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-12-19
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

--! Data strobed Sin & Cos lookup table. Finds new values every time strobe_in 
--! goes high and outputs them with strobe_out.
--! Outputs cos(2*pi*angle) and sin(2*pi*angle), where 0 <= angle < 1.
--!
--! @todo add generic option to use quarter-wave lookup tables and make it the 
--! default.
--!
entity strobed_trig_table is
  port (
    clk : in std_logic; --! Clock line
    rst : in std_logic; --! Reset Line
    angle : in ufixed; --! Normalized angle (0 <= angle < 1)
    strobe_in : in std_logic; --! Data strobe input
    sine : out sfixed; --! sin(2*pi*angle)
    cosine : out sfixed; --! cos(2*pi*angle)
    strobe_out : out std_logic --! Data strobe output
  );
end entity;

--! Uses two lookup tables to find sin & cos. Future version will use 
--! quarter-wave lookup tables as default.
architecture rtl of strobed_trig_table is

  --! Function for generating sine lookup table
  function sine_table (angle_width : natural; sine_high, sine_low : integer) return sfixed_vector is
    --! Size of lookup table - 1
    constant table_high : positive := 2**angle_width - 1;
    --! Working copy of lookup table to return
    variable table : sfixed_vector(table_high downto 0)
      (sine_high downto sine_low);
    --! Working value of sine to convert for lookup table
    variable sine_real : real;
  begin
    for i in 0 to table_high loop
      sine_real := sin(math_2_pi * (real(i) / real(table_high + 1)));
      table(i) := to_sfixed(sine_real, sine_high, sine_low);
    end loop;
    return table;
  end function;
  
  --! Function for generating cosine lookup table
  function cosine_table (angle_width : natural; cosine_high, cosine_low : integer) return sfixed_vector is
    --! Size of lookup table - 1
    constant table_high : positive := 2**angle_width - 1;
    --! Working copy of lookup table to return
    variable table : sfixed_vector(table_high downto 0)
      (cosine_high downto cosine_low);
    --! Working value of cosine to convert for lookup table
    variable cosine_real : real;
  begin
    for i in 0 to table_high loop
      cosine_real := cos(math_2_pi * (real(i) / real(table_high + 1)));
      table(i) := to_sfixed(cosine_real, cosine_high, cosine_low);
    end loop;
    return table;
  end function;

  --! Total width of useful angle bits (-1 downto angle'low)
  constant angle_width : positive := 0 - angle'low;

  constant sine_lookup_table : sfixed_vector :=
    sine_table(angle_width, sine'high, sine'low);
  constant cosine_lookup_table : sfixed_vector :=
    cosine_table(angle_width, cosine'high, cosine'low);

  --! std_logic_vector version of angle for lookup table
  signal lookup_bits : std_logic_vector((angle_width - 1) downto 0);

begin

  --! State assumptions
  assert (angle'low < 0)
    report "Angle to trig table should be a fraction from 0 to 1"
    severity warning;
  assert (angle'high < 0)
    report "Any integer bits in the input angle will be unused"
    severity warning;
  assert (sine'high < 2)
    report "Sine will range from 1 to -1; more integer bits not necessary"
    severity warning;
  assert (cosine'high < 2)
    report "Sine will range from 1 to -1; more integer bits not necessary"
    severity warning;

  --! Casts the ufixed angle value as a std_logic_vectro for the lookup table.
  --! @todo There's got to be a more elegant way of doing this.
  remap_lookup_bits : for i in lookup_bits'range generate
    lookup_bits(i) <= std_logic(angle(i - angle_width));
  end generate;

  --! Pipeline to look up values
  data_pipeline : process (clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        sine <= to_sfixed(0.0, sine);
        cosine <= to_sfixed(0.0, cosine);
        strobe_out <= '0';
      else
        sine <= sine_lookup_table(to_integer(unsigned(lookup_bits)));
        cosine <= cosine_lookup_table(to_integer(unsigned(lookup_bits)));
        strobe_out <= strobe_in;
      end if;
    end if;
  end process;

end rtl;
