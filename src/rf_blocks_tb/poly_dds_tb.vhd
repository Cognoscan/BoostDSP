--! @file poly_dds_tb.vhd
--! @brief Polyphase Direct Digital Synthesizer Testbench
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

library boostdsp;
use boostdsp.fixed_pkg.all;
use boostdsp.util_pkg.all;
use boostdsp.rf_blocks_pkg;

--! Tests the boostdsp.dds entity.
entity poly_dds_tb is
end entity;

architecture sim of poly_dds_tb is

  constant NUM_CHANNELS : positive := 16;
  constant CH_MAX : positive := NUM_CHANNELS - 1;

  constant clk_p : time := 10 ns;
  constant clk_hp : time := clk_p / 2;

  signal clk   : std_logic := '0';
  signal rst   : std_logic := '1';
  signal freq  : ufixed(-1 downto -9) := to_ufixed(0.1, -1, -9);
  signal phase : ufixed(-1 downto -9) := to_ufixed(0, -1, -9);
  signal i_out : sfixed_vector(0 to CH_MAX)(1 downto -6);
  signal q_out : sfixed_vector(0 to CH_MAX)(1 downto -6);

  signal vis_i_out : signed_vector(0 to CH_MAX)(7 downto 0);
  signal vis_q_out : signed_vector(0 to CH_MAX)(7 downto 0);

  signal vis_combined_i : signed(7 downto 0);
  signal vis_combined_q : signed(7 downto 0);

begin

  --! Polyphase DDS Unit Under Test
  uut: rf_blocks_pkg.poly_dds
  port map(
    clk   => clk,
    rst   => rst,
    freq  => freq,
    phase => phase,
    i_out => i_out,
    q_out => q_out
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
    wait for clk_p * 4;
    rst <= '0';
    wait;
  end process;

  --! Test the phase shifting input
  phase_test_proc : process
  begin
    wait for clk_p * 20;
    phase <= to_ufixed(0.2, phase);
    wait for clk_p * 20;
    phase <= to_ufixed(0.5, phase);
    wait for clk_p * 20;
    phase <= to_ufixed(0, phase);
    wait;
  end process;

  --! Visualize all generated sinusoids
  visualize : for i in i_out'range generate
    vis_i_out(i) <= sfixed_as_signed(i_out(i));
    vis_q_out(i) <= sfixed_as_signed(q_out(i));
  end generate;

  --! Upconvert and serialize all sinusoids to get high-speed sinusoids
  visualize_combined : process
  begin
    wait until rising_edge(clk);
    wait for clk_p / (i_out'length + 2);
    while true loop
    for i in i_out'range loop
      vis_combined_i <= vis_i_out(i);
      vis_combined_q <= vis_q_out(i);
      wait for clk_p / i_out'length;
    end loop;
  end loop;
  end process;


end sim;
