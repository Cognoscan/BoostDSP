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


--! Tests FIR filter block with a LPF and a chirp signal.
entity fir_tb is
end entity;

architecture sim of fir_tb is

  constant clk_p : time := 10 ns;
  constant clk_hp : time := 5 ns;

  constant REAL_COEFFS : real_vector(63 downto 0) := (
  -0.0007796429301286012,
  -0.0003156007529416889,
  0.0005104741442584588,
  0.001115485185756897,
  0.0008643801790044494,
  -0.0003846385387076593,
  -0.00183918445351239,
  -0.002077420576641017,
  -0.0002510365880192294,
  0.002695337022541216,
  0.004184383430860367,
  0.002031565039549675,
  -0.00306899653280024,
  -0.007098961443542058,
  -0.005582520200756744,
  0.00200818527942565,
  0.01030833822049713,
  0.01138895742129619,
  0.001745680998188937,
  -0.01281040110449648,
  -0.01978810419497967,
  -0.009911152225648579,
  0.01298352224579553,
  0.03131851689393891,
  0.02568859991818818,
  -0.007811875644557511,
  -0.0484513087840436,
  -0.05967613596766252,
  -0.01288337785600386,
  0.08935832005638873,
  0.2082005359335768,
  0.2877613466436248,
  0.2877613466436248,
  0.2082005359335768,
  0.08935832005638873,
  -0.01288337785600386,
  -0.05967613596766252,
  -0.04845130878404361,
  -0.007811875644557514,
  0.02568859991818819,
  0.03131851689393892,
  0.01298352224579553,
  -0.009911152225648576,
  -0.01978810419497967,
  -0.01281040110449649,
  0.001745680998188937,
  0.0113889574212962,
  0.01030833822049713,
  0.002008185279425651,
  -0.005582520200756746,
  -0.007098961443542059,
  -0.003068996532800242,
  0.002031565039549676,
  0.004184383430860365,
  0.002695337022541217,
  -0.0002510365880192294,
  -0.002077420576641019,
  -0.001839184453512392,
  -0.0003846385387076598,
  0.0008643801790044497,
  0.001115485185756897,
  0.0005104741442584587,
  -0.0003156007529416892,
  -0.0007796429301286012
);

constant COEFFS : sfixed_vector(REAL_COEFFS'range)(0 downto -15) :=
  to_sfixed_vector(REAL_COEFFS, 0, -15);

signal clk : std_logic := '0'; --! Clock line
signal rst : std_logic := '1'; --! Reset line
signal din : sfixed(1 downto -7); --! Data input
signal dout : sfixed(1 downto -7); --! Data output

signal angle : ufixed(0 downto -10) := to_ufixed(0,0,-10); --! Angle counter
signal inc : ufixed(-1 downto -10) := to_ufixed(0,-1,-10); --! Angle increment counter

signal sine : sfixed(1 downto -7); --! Unused sine output

signal vis_din : signed(8 downto 0);
signal vis_dout : signed(8 downto 0);

begin

  --! Pipelined FIR filter. Can be configured to be a symmetric filter, and takes 
  --! in coefficients as it runs. The upper and lower bits of the fixed-point 
  --! accumulators must be set by the user. The recommended values of these are 
  --! vendor- and application-dependent, and thus cannot be calculated within this 
  --! entity.
  uut : basic_pkg.fir
    generic map (
    SYMMETRIC => false,
    EVEN      => false,
    UPPER_BIT => 11,
    LOWER_BIT => -18
  )
  port map (
         clk   => clk,
         rst   => rst,
         coeff => COEFFS,
         din   => din,
         dout  => dout
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
  vis_dout <= sfixed_as_signed(dout);

end sim;
