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
use ieee.fixed_float_types.all;

--! Local version of the fixed point package
use work.fixed_pkg.all;
--! Basic design elements
use work.basic_pkg;

--! Direct Digital Synthesizer. Generates 2 sinusoidal waves 90 degrees out of 
--! phase with each other. Frequency is determined by freq, which should be some 
--! value between 0 and 1. Realistically, this value will only be between 0 and 
--! 0.5, where i_out[n] = cos(2*pi*freq*n) and q_out[n] = sin(2*pi*freq*n).
entity dds is
  port (
    clk   : in std_logic; --! Clock line
    rst   : in std_logic; --! Reset line
    freq  : in ufixed;    --! Frequency input
    phase : in ufixed;    --! Additional phase offset
    i_out : out sfixed;   --! I Sinusoidal output
    q_out : out sfixed    --! Q Sinusoidal output
  );
end entity dds;

--! Phase accumulator-base DDS architecture. Uses a phase accumulator that adds 
--! freq to phase_acc every clock cycle. The phase offset is then added on to 
--! get the angle. This signal angle then feeds the trigometric look-up 
--! table. The outputs of this look-up table is the DDS output.
architecture rtl of dds is

  --! Angle of DDS before adding phase offset (phase accumulator)
  signal phase_acc : ufixed(-1 downto freq'low);

  --! Current angle of DDS (phase register)
  signal angle : ufixed(-1 downto freq'low); 

begin

  --! State assumptions
  assert freq'high < 0
    report "Frequency bits above -1 not used (freq = 0 to 1)"
    severity warning;
  assert phase'high < 0
    report "Phase bits above -1 not used (phase accumulator = 0 to 1)"
    severity warning;

  --! Phase accumulator and angle calculation
  phase_inc : process (clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        phase_acc <= to_ufixed(0, phase_acc);
        angle <= to_ufixed(0, angle);
      else
        phase_acc <= resize(phase_acc + freq, phase_acc'high, phase_acc'low,
                     fixed_wrap, fixed_truncate);
        angle <= resize(phase_acc + phase, angle'high, angle'low,
                 fixed_wrap, fixed_truncate);
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
