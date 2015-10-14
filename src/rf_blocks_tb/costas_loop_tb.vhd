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
use boostdsp.basic_pkg;
use boostdsp.rf_blocks_pkg;

entity costas_loop_tb is
  end entity;

architecture sim of costas_loop_tb is

  constant clk_p : time := 10 ns;
  constant clk_hp : time := clk_p / 2;

  constant freq_init : ufixed(-1 downto -10) := to_ufixed(0.1, -1, -10);
  constant phase_init : ufixed(-1 downto -10) := to_ufixed(0, -1, -10);

  constant phase_track : ufixed(-1 downto -10) := to_ufixed(0, -1, -10);

  constant REAL_COEFFS_EVEN : real_vector(0 to 63) := (
     -0.0007796429301286012,   -0.0003156007529416889,   0.0005104741442584588,
     0.001115485185756897,     0.0008643801790044494,    -0.0003846385387076593,
     -0.00183918445351239,     -0.002077420576641017,    -0.0002510365880192294,
     0.002695337022541216,     0.004184383430860367,     0.002031565039549675,
     -0.00306899653280024,     -0.007098961443542058,    -0.005582520200756744,
     0.00200818527942565,      0.01030833822049713,      0.01138895742129619,
     0.001745680998188937,     -0.01281040110449648,     -0.01978810419497967,
     -0.009911152225648579,    0.01298352224579553,      0.03131851689393891,
     0.02568859991818818,      -0.007811875644557511,    -0.0484513087840436,
     -0.05967613596766252,     -0.01288337785600386,     0.08935832005638873,
     0.2082005359335768,       0.2877613466436248,       0.2877613466436248,
     0.2082005359335768,       0.08935832005638873,      -0.01288337785600386,
     -0.05967613596766252,     -0.04845130878404361,     -0.007811875644557514,
     0.02568859991818819,      0.03131851689393892,      0.01298352224579553,
     -0.009911152225648576,    -0.01978810419497967,     -0.01281040110449649,
     0.001745680998188937,     0.0113889574212962,       0.01030833822049713,
     0.002008185279425651,     -0.005582520200756746,    -0.007098961443542059,
     -0.003068996532800242,    0.002031565039549676,     0.004184383430860365,
     0.002695337022541217,     -0.0002510365880192294,   -0.002077420576641019,
     -0.001839184453512392,    -0.0003846385387076598,   0.0008643801790044497,
     0.001115485185756897,     0.0005104741442584587,    -0.0003156007529416892,
     -0.0007796429301286012);

  constant FIR_COEFFS : sfixed_vector(0 to 31)(0 downto -15) :=
    to_sfixed_vector(REAL_COEFFS_EVEN(0 to 31), 0, -15);

  signal clk : std_logic := '0';
  signal rst : std_logic := '1';

  signal i_in : sfixed(1 downto -10);
  signal q_in : sfixed(1 downto -10);
  signal i_out : sfixed(1 downto -10);
  signal q_out : sfixed(1 downto -10);

  signal i_down : sfixed(1 downto -10) := to_sfixed(0, 1, -10);
  signal q_down : sfixed(1 downto -10) := to_sfixed(0, 1, -10);
  signal mix_down : sfixed(1 downto -10) := to_sfixed(0, 1, -10);

  signal freq_track : sfixed(-1 downto -10);
  signal u_freq_track : ufixed(-1 downto -10) := to_ufixed(0.05, -1, -10);

  signal vis_i_in : signed(11 downto 0);
  signal vis_q_in : signed(11 downto 0);
  signal vis_i_out : signed(11 downto 0);
  signal vis_q_out : signed(11 downto 0);
  signal vis_freq_track : signed(9 downto 0);

begin

  dds_main : rf_blocks_pkg.dds
    port map (
           clk   => clk,
           rst   => rst,
           freq  => freq_init,
           phase => phase_init,
           i_out => i_in,
           q_out => q_in
         );

  dds_track : rf_blocks_pkg.dds
    port map (
           clk   => clk,
           rst   => rst,
           freq  => u_freq_track,
           phase => phase_track,
           i_out => i_out,
           q_out => q_out
         );

  u_freq_track <= to_ufixed(freq_track);


  loop_filter : basic_pkg.fir
    generic map (
    SYMMETRIC => true,
    EVEN      => true,
    UPPER_BIT => 11,
    LOWER_BIT => -18
  )
  port map (
         clk   => clk,
         rst   => rst,
         coeff => FIR_COEFFS,
         din   => mix_down,
         dout  => freq_track
       );

  clk_proc : process
  begin
    wait for clk_hp;
    clk <= not clk;
  end process;

  rst_proc : process
  begin
    wait for clk_p * 4;
    rst <= '0';
    wait;
  end process;

  mixers : process
  begin
    wait until rising_edge(clk);
    i_down <= resize(i_in * i_out, i_down'high, i_down'low);
    q_down <= resize(q_in * q_out, q_down'high, q_down'low);
    mix_down <= resize(i_down * q_down, mix_down'high, mix_down'low);
  end process;


  vis_i_in <= sfixed_as_signed(i_in);
  vis_q_in <= sfixed_as_signed(q_in);
  vis_i_out <= sfixed_as_signed(i_out);
  vis_q_out <= sfixed_as_signed(q_out);
  vis_freq_track <= sfixed_as_signed(freq_track);

end sim;
