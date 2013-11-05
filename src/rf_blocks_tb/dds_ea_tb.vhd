--! @file dds_tb.vhd
--! @brief Direct Digital Synthesizer Testbench
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

library boostdsp;
use boostdsp.fixed_pkg.all;
use boostdsp.rf_blocks_pkg;

--! Tests the boostdsp.dds entity.
entity dds_tb is
end entity;

architecture sim of dds_tb is

constant clk_hp : time := 1 ns;

signal clk   : std_logic := '0';
signal rst   : std_logic := '1';
signal freq  : ufixed(-1 downto -9) := to_ufixed(0.1, -1, -9);
signal i_out : sfixed(1 downto -6);
signal q_out : sfixed(1 downto -6);

signal vis_i_out : signed((i_out'length - 1) downto 0);
signal vis_q_out : signed((q_out'length - 1) downto 0);

begin

  uut : rf_blocks_pkg.dds
    port map (
           clk   => clk,
           rst   => rst,
           freq  => freq,
           i_out => i_out,
           q_out => q_out
         );

  clk_proc : process
  begin
    wait for clk_hp;
    clk <= not clk;
  end process;

  rst_proc : process
  begin
    wait for clk_hp * 4;
    rst <= '0';
    wait;
  end process;

  vis_q_out_gen : for i in vis_q_out'range generate
    vis_q_out(i) <= std_logic(q_out(i - (q_out'high - q_out'low) + 1));
  end generate;

  vis_i_out_gen : for i in vis_i_out'range generate
    vis_i_out(i) <= std_logic(i_out(i - (i_out'high - i_out'low) + 1));
  end generate;


end sim;
