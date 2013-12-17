--! @file poly_dds_ea.vhd
--! @brief Polyphase Direct Digital Synthesizer
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-12-17
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
use ieee.fixed_float_types.all;

--! Local version of the fixed point package
use work.fixed_pkg.all;
--! Utility package
use work.util_pkg.all;
--! Basic design elements
use work.basic_pkg;

--! Polyphase Direct Digital Synthesizer. For each phase channel, generates 
--! 2 sinusoidal waves 90 degrees out of phase with each other. Frequency is 
--! determined by freq, which should be some value between 0 and 1. 
entity poly_dds is
  port (
    clk : in std_logic; --! Clock line
    rst : in std_logic; --! Reset line
    freq : in ufixed; --! Frequency input
    i_out : out sfixed_vector; --! I Sinusoidal output vector
    q_out : out sfixed_vector  --! Q Sinusoidal output vector
  );
end entity poly_dds;

architecture rtl of poly_dds is

  --! Registered freq value
  signal freq_reg : ufixed(freq'range);

  --! Scaled freq value to increment angle by
  signal angle_freq : ufixed(freq'range);

  --! Scaled freq values for use in finding phases
  signal scaled_freqs : ufixed_vector(i_out'range)(freq'range);

  --! Current angle of DDS (primary phase register)
  signal angle : ufixed(-1 downto freq'low);

  --! Adjusted angles of DDS
  signal phases : ufixed_vector(i_out'range)(-1 downto freq'low);

begin

  --! State assumptions
  assert freq'high < 0
    report "Frequency bits above -1 not used (freq = 0 to 1)"
    severity warning;
  assert i_out'high = q_out'high
    report "Not equal number of i_out and q_out (high indices don't match"
    severity error;
  assert i_out'low = q_out'low
    report "Not equal number of i_out and q_out (low indices don't match"
    severity error;
  assert i_out'low = 0
    report "Low index of i_out & q_out must be 0"
    severity error;

  --! Frequency register pipeline
  freq_pipeline : process(clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        freq_reg <= to_ufixed(0, freq_reg);
        angle_freq <= to_ufixed(0, angle_freq'high, angle_freq'low);
        scaled_freqs <= (others => to_ufixed(0,
                        scaled_freqs'element'high, scaled_freqs'element'low));
      else
        freq_reg <= freq;
        angle_freq <= resize(freq_reg *
                      to_ufixed(i_out'length, get_counter_width(i_out'high), 0),
                      angle_freq'high, angle_freq'low,
                      fixed_wrap, fixed_truncate);
        for i in i_out'range loop
          scaled_freqs(i) <= resize(freq_reg *
                             to_ufixed(i, get_counter_width(i_out'high), 0),
                             scaled_freqs(i)'high, scaled_freqs(i)'low,
                             fixed_wrap, fixed_truncate);
        end loop;
      end if; -- rst
    end if; -- clk
  end process;

  --! Phase incrementers
  phase_inc : process (clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        angle <= to_ufixed(0, angle);
        phases <= (others => to_ufixed(0,
                  phases'element'high, phases'element'low));
      else
        angle <= resize(angle + angle_freq, angle'high, angle'low,
                 fixed_wrap, fixed_truncate);
        for i in i_out'range loop
          phases(i) <= resize(angle + scaled_freqs(i),
                       phases(i)'high, phases(i)'low,
                       fixed_wrap, fixed_truncate);
        end loop;
      end if;
    end if;
  end process;

  --! Generate Trig Lookup Tables
  trig_table_gen : for i in i_out'range generate
    trig_table_x : basic_pkg.trig_table
    port map (
               clk => clk,
               rst => rst,
               angle => phases(i),
               sine => q_out(i),
               cosine => i_out(i)
             );
  end generate;

end rtl;
