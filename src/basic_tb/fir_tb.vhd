--! @file fir_tb.vhd
--! @brief FIR Filter testbench
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-12-16
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

--! Standard IEEE Library
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_float_types.all;

library boostdsp;
use boostdsp.fixed_pkg.all;
use boostdsp.util_pkg.all;
use boostdsp.basic_pkg;


--! Tests FIR filter block with a LPF and a chirp signal. Four UUTs are made, in 
--! order to test the symmetric feature of the FIR entity:
--!
--! - UUT_EVEN: Even number of coefficients, non-symmetric FIR.
--! - UUT_ODD: Odd number of coefficients, non-symmetric FIR.
--! - UUT_SYM_EVEN: Even number of coefficients, symmetric FIR.
--! - UUT_SYM_ODD: Odd number of coefficients, symmetric FIR.
--!
entity fir_tb is
end entity;

architecture sim of fir_tb is

  constant clk_p : time := 10 ns;
  constant clk_hp : time := 5 ns;

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

  constant REAL_COEFFS_ODD : real_vector(0 to 62) := (
     -0.0006138293903634735,   8.003835073700828e-05,   0.0008397928119963468,
     0.001055818890924725,     0.0003162760183783588,   -0.001094704195217394,
     -0.002057938256400296,    -0.001331422891045849,   0.001156476318373019,
     0.003619816555873643,     0.003454981950457361,    -0.0003287487374615011,
     -0.005355819231686653,    -0.006995253887650727,   -0.002278625327132272,
     0.006436256492672024,     0.01192982859845966,     0.007652107523815416,
     -0.005558469988600605,    -0.01784007788225709,    -0.01693780310337196,
     0.0007643700081735891,    0.02395811472312631,     0.03214425879194105,
     0.01165925638155491,      -0.02932110120691753,    -0.05995490496263704,
     -0.04425295132419316,     0.03299420563349268,     0.1501945700109821,
     0.2562677744312201,       0.2989441793768482,      0.2562677744312201,
     0.150194570010982,        0.03299420563349268,     -0.04425295132419315,
     -0.05995490496263704,     -0.02932110120691753,    0.01165925638155491,
     0.03214425879194105,      0.02395811472312631,     0.0007643700081735889,
     -0.01693780310337196,     -0.0178400778822571,     -0.00555846998860061,
     0.007652107523815416,     0.01192982859845967,     0.006436256492672023,
     -0.002278625327132272,    -0.006995253887650731,   -0.005355819231686654,
     -0.0003287487374615018,   0.003454981950457361,    0.003619816555873645,
     0.001156476318373019,     -0.001331422891045848,   -0.002057938256400296,
     -0.001094704195217394,    0.0003162760183783585,   0.001055818890924726,
     0.0008397928119963479,    8.003835073700848e-05,   -0.0006138293903634741);
  
constant COEFFS_EVEN : sfixed_vector(0 to 63)(0 downto -15) :=
  to_sfixed_vector(REAL_COEFFS_EVEN(0 to 63), 0, -15);
constant COEFFS_ODD : sfixed_vector(0 to 62)(0 downto -15) :=
  to_sfixed_vector(REAL_COEFFS_ODD(0 to 62), 0, -15);
constant COEFFS_SYM_EVEN : sfixed_vector(0 to 31)(0 downto -15) :=
  to_sfixed_vector(REAL_COEFFS_EVEN(0 to 31), 0, -15);
constant COEFFS_SYM_ODD : sfixed_vector(0 to 31)(0 downto -15) :=
  to_sfixed_vector(REAL_COEFFS_ODD(0 to 31), 0, -15);

signal clk : std_logic := '0'; --! Clock line
signal rst : std_logic := '1'; --! Reset line
signal din : sfixed(1 downto -7); --! Data input

signal dout_even : sfixed(1 downto -7); --! Data output
signal dout_odd : sfixed(1 downto -7); --! Data output
signal dout_sym_even : sfixed(1 downto -7); --! Data output
signal dout_sym_odd : sfixed(1 downto -7); --! Data output

signal angle : ufixed(0 downto -10) := to_ufixed(0,0,-10); --! Angle counter
signal inc : ufixed(-1 downto -10) := to_ufixed(0,-1,-10); --! Angle increment counter

signal sine : sfixed(1 downto -7); --! Unused sine output

signal vis_din : signed(8 downto 0);

signal vis_dout_even : signed(8 downto 0);
signal vis_dout_odd : signed(8 downto 0);
signal vis_dout_sym_even : signed(8 downto 0);
signal vis_dout_sym_odd : signed(8 downto 0);

begin

  --! Non-symmetric, even FIR filter
  uut_even : basic_pkg.fir
    generic map (
    SYMMETRIC => false,
    EVEN      => true,
    UPPER_BIT => 11,
    LOWER_BIT => -18
  )
  port map (
         clk   => clk,
         rst   => rst,
         coeff => COEFFS_EVEN,
         din   => din,
         dout  => dout_even
       );

  --! Non-symmetric, odd FIR filter
  uut_odd : basic_pkg.fir
    generic map (
    SYMMETRIC => false,
    EVEN      => false,
    UPPER_BIT => 11,
    LOWER_BIT => -18
  )
  port map (
         clk   => clk,
         rst   => rst,
         coeff => COEFFS_ODD,
         din   => din,
         dout  => dout_odd
       );

  --! Symmetric, even FIR filter
  uut_sym_even : basic_pkg.fir
    generic map (
    SYMMETRIC => true,
    EVEN      => true,
    UPPER_BIT => 11,
    LOWER_BIT => -18
  )
  port map (
         clk   => clk,
         rst   => rst,
         coeff => COEFFS_SYM_EVEN,
         din   => din,
         dout  => dout_sym_even
       );

  --! Symmetric, odd FIR filter
  uut_sym_odd : basic_pkg.fir
    generic map (
    SYMMETRIC => true,
    EVEN      => false,
    UPPER_BIT => 11,
    LOWER_BIT => -18
  )
  port map (
         clk   => clk,
         rst   => rst,
         coeff => COEFFS_SYM_ODD,
         din   => din,
         dout  => dout_sym_odd
       );

--! Sin & Cos lookup table.
--! Outputs cos(2*pi*angle) and sin(2*pi*angle), where 0 <= angle < 1.
  sig_gen : basic_pkg.trig_table
    port map (
           clk    => clk,
           rst    => rst,
           angle  => angle,
           sine   => sine,
           cosine => din
         );

  clk_proc : process
  begin
    wait for clk_hp;
    clk <= not clk;
  end process;

  rst_proc : process
  begin
    wait for clk_p*4;
    rst <= '0';
    wait;
  end process;

  angle_proc : process(clk)
  begin
    if rising_edge(clk) then
      angle <= resize(angle + inc, angle'high, angle'low,
               fixed_wrap, fixed_truncate);
    end if;
  end process;

  inc_proc : process
  begin
    wait for clk_p;
    inc <= resize(inc + 0.001, inc'high, inc'low,
           fixed_wrap, fixed_truncate);
  end process;

  vis_din <= sfixed_as_signed(din);
  
  vis_dout_even <= sfixed_as_signed(dout_even);
  vis_dout_odd <= sfixed_as_signed(dout_odd);
  vis_dout_sym_even <= sfixed_as_signed(dout_sym_even);
  vis_dout_sym_odd <= sfixed_as_signed(dout_sym_odd);

end sim;
