--! @file dds_ea.vhd
--! @brief Direct Digital Synthesizer
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

--! Local version of the fixed point package
use work.fixed_pkg.all;
--! Basic design elements
use work.basic_pkg;

entity dds is
  port (
    clk : in std_logic;
    rst : in std_logic;
    freq : in ufixed;
    i_out : out sfixed;
    q_out : out sfixed
  );
end entity dds;

architecture rtl of dds is

  constant freq_width : positive := 0 - freq'low;

  signal freq_bits : unsigned((freq_width - 1) downto 0);
  signal angle : ufixed(-1 downto freq'low);

  signal phase_counter : unsigned((freq_width - 1) downto 0);

begin

  assert freq'high < 0
    report "Frequency bits above -1 not used (freq = 0 to 1)"
    severity warning;

  -- Generate an unsigned value to use for system.
  -- Also generate a fixed point angle value to feed to trig_table.
  ufixed_unsigned_conv : for i in freq_bits'range generate
    freq_bits(i) <= freq(i - freq_width);
    angle(i - freq_width) <= phase_counter(i);
  end generate;

  phase_inc : process (clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        phase_counter <= to_unsigned(0, phase_counter'length);
      else
        phase_counter <= phase_counter + freq_bits;
      end if;
    end if;
  end process;

  trig_table_1 : basic_pkg.trig_table
    port map (
      clk => clk,
      rst => rst,
      angle => angle,
      sine => q_out,
      cosine => i_out
    );

end rtl;
