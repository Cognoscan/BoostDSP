--! @file trig_table_ea.vhd
--! @brief sin/cos lookup table generator
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-09-30
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

--! Sin & Cos lookup table.
--! Outputs cos(2*pi*angle) and sin(2*pi*angle), where 0 <= angle < 1.
entity trig_table is
  port (
    clk : in std_logic;
    rst : in std_logic;
    angle : in unsigned;
    sine : out sfixed;
    cosine : out sfixed
  );
end entity;

architecture rtl of trig_table is

  function sine_table (angle_width : natural; sine_high, sine_low : integer) return sfixed_vector is
    constant table_high : positive := 2**angle_width - 1;
    variable table : sfixed_vector(table_high downto 0)
      (sine_high downto sine_low);
    variable sine_real : real;
  begin
    for i in 0 to table_high loop
      sine_real := sin(math_2_pi * (real(i) / real(table_high + 1)));
      table(i) := to_sfixed(sine_real, sine_high, sine_low);
    end loop;
    return table;
  end function;
  
  function cosine_table (angle_width : natural; cosine_high, cosine_low : integer) return sfixed_vector is
    constant table_high : positive := 2**angle_width - 1;
    variable table : sfixed_vector(table_high downto 0)
      (cosine_high downto cosine_low);
    variable cosine_real : real;
  begin
    for i in 0 to table_high loop
      cosine_real := cos(math_2_pi * (real(i) / real(table_high + 1)));
      table(i) := to_sfixed(cosine_real, cosine_high, cosine_low);
    end loop;
    return table;
  end function;

  constant angle_width : positive := 0 - angle'low;

  constant sine_lookup_table : sfixed_vector :=
    sine_table(angle_width, sine'high, sine'low);
  constant cosine_lookup_table : sfixed_vector :=
    cosine_table(angle_width, cosine'high, cosine'low);

  signal lookup_bits : std_logic_vector((angle_width - 1) downto 0);

begin
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

  remap_lookup_bits : for i in lookup_bits'range generate
    lookup_bits(i) <= std_logic(angle(i - angle_width));
  end generate;

  data_pipeline : process (clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        sine <= to_sfixed(0.0, sine);
        cosine <= to_sfixed(0.0, cosine);
      else
        sine <= sine_lookup_table(to_integer(unsigned(lookup_bits)));
        cosine <= cosine_lookup_table(to_integer(unsigned(lookup_bits)));
      end if;
    end if;
  end process;

end rtl;
