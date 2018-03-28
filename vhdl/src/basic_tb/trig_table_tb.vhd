--! @file trig_table_tb.vhd
--! @brief sin/cos lookup table generator testbench
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-11-2
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

library boostdsp;
use boostdsp.fixed_pkg.all;
use boostdsp.util_pkg.all;
use boostdsp.basic_pkg;

--! Tests the boostdsp.trig_table entity.
--! @TODO Use sfixed_as_signed to get vis_sine & vis_cosine.
entity trig_table_tb is
end entity;

--! Tests the boostdsp.trig_table entity by running through all possible angle 
--! values.
architecture sim of trig_table_tb is

--! Half period of clock line
constant clk_hp : time := 1 ns;

signal clk     : std_logic := '0'; --! Clock for UUT
signal rst     : std_logic := '1'; --! Reset for UUT
signal angle   : ufixed(-1 downto -9) := to_ufixed(0.0, -1, -9); --! Input angle
signal sine    : sfixed(1 downto -6); --! Sine output
signal cosine  : sfixed(1 downto -6); --! Cosine output
signal sine2   : sfixed(1 downto -6); --! Sine output, uut2
signal cosine2 : sfixed(1 downto -6); --! Cosine output, uut2

signal vis_sine    : signed(7 downto 0); --! Visualize output in Modelsim
signal vis_cosine  : signed(7 downto 0); --! Visualize output in Modelsim
signal vis_sine2   : signed(7 downto 0); --! Visualize output in Modelsim
signal vis_cosine2 : signed(7 downto 0); --! Visualize output in Modelsim

constant angle_lsb : real := 2.0**(angle'low); --! LSB of angle counter

signal test_out : sfixed(
  sfixed_high(sine'high, sine'low, '*', sine'high, sine'low) + 1 downto
  sfixed_low( sine'high, sine'low, '*', sine'high, sine'low));

signal test_out2 : sfixed(
  sfixed_high(sine'high, sine'low, '*', sine'high, sine'low) + 1 downto
  sfixed_low( sine'high, sine'low, '*', sine'high, sine'low));

signal vis_test  : signed(test_out'length - 1 downto 0);
signal vis_test2 : signed(test_out2'length - 1 downto 0);

begin

  --! Trigometric Table Unit Under Test
  uut : basic_pkg.trig_table
  generic map (
    QUARTER_WAVE => true
  )
  port map (
    clk    => clk,
    rst    => rst,
    angle  => angle,
    sine   => sine,
    cosine => cosine
  );

  --! Trigometric Table Unit Under Test
  uut2 : basic_pkg.trig_table
  generic map (
    QUARTER_WAVE => false
  )
  port map (
    clk    => clk,
    rst    => rst,
    angle  => angle,
    sine   => sine2,
    cosine => cosine2
  );

  --! Clock generator
  clk_proc : process
  begin
    wait for clk_hp;
    clk <= not clk;
  end process;

  --! Reset generator
  rst_proc : process
  begin
    wait for clk_hp * 4;
    rst <= '0';
    wait;
  end process;

  --! Incremeting angle through entire range
  test_input : process
  begin
    wait for clk_hp * 2;
    angle <= resize(angle + to_ufixed(angle_lsb,angle), angle'high, angle'low,
             fixed_wrap, fixed_truncate);
  end process;

  test_out <= sine*sine + cosine*cosine;
  test_out2 <= sine2*sine2 + cosine2*cosine2;

  --! Visualize sine & cosine output
  vis_sine    <= sfixed_as_signed(sine);
  vis_cosine  <= sfixed_as_signed(cosine);
  vis_sine2   <= sfixed_as_signed(sine2);
  vis_cosine2 <= sfixed_as_signed(cosine2);

  vis_test <= sfixed_as_signed(test_out);
  vis_test2 <= sfixed_as_signed(test_out2);

end sim;
