--! @file basic_tx_tb.vhd
--! @brief Frame Transmit Handler testbench
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-11-06
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
use boostdsp.basic_pkg;
use boostdsp.comm_systems_pkg;

--! Tests the boostdsp.dds entity.
entity simple_tx_tb is
end entity;

architecture sim of simple_tx_tb is

constant clk_hp : time := 1 ns;

  signal clk               : std_logic := '1';
  signal rst               : std_logic := '1';
  signal frame_size        : unsigned(3 downto 0) := to_unsigned(5, 4);
  signal clks_per_symbol   : unsigned(3 downto 0) := to_unsigned(9, 4);
  signal start             : std_logic := '0';
  signal abort             : std_logic := '0';
  signal frame_tx_complete : std_logic;
  signal buffer_addr       : std_logic_vector(3 downto 0) := (others => '0');
  signal buffer_we         : std_logic := '0';
  signal buffer_write_data : std_logic_vector(7 downto 0) := (others => '0');
  signal buffer_read_data  : std_logic_vector(7 downto 0) := (others => '0');
  signal buffer_strobe     : std_logic := '0';
  signal buffer_done       : std_logic;
  signal freq              : ufixed(-1 downto -9) := to_ufixed(0.1, -1, -9);
  signal i_out             : sfixed(1 downto -6);
  signal q_out             : sfixed(1 downto -6);
  signal vis_i_out         : signed(7 downto 0);
  signal vis_q_out         : signed(7 downto 0);

begin
  uut : comm_systems_pkg.simple_tx
  generic map (
    INCLUDE_DDS  => true,
    MAP_VALUES_I => basic_pkg.qam16_i,
    MAP_VALUES_Q => basic_pkg.qam16_q
  ) 
    port map (
           clk               => clk,
           rst               => rst,
           frame_size        => frame_size,
           clks_per_symbol   => clks_per_symbol,
           start             => start,
           abort             => abort,
           frame_tx_complete => frame_tx_complete,
           buffer_addr       => buffer_addr,
           buffer_we         => buffer_we,
           buffer_write_data => buffer_write_data,
           buffer_read_data  => buffer_read_data,
           buffer_strobe     => buffer_strobe,
           buffer_done       => buffer_done,
           freq              => freq,
           i_out             => i_out,
           q_out             => q_out
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

  run_system : process
    variable seed1, seed2 : positive;
    variable rand : real;
    variable int_rand : integer;
  begin
    uniform(seed1, seed2, rand);
    wait until rst = '0' and rising_edge(clk);
    for i in 0 to (2**buffer_addr'length - 1) loop
      wait until buffer_done = '0';
      wait until rising_edge(clk);
      buffer_addr <= std_logic_vector(to_unsigned(i, buffer_addr'length));
      uniform(seed1, seed2, rand);
      int_rand := integer(trunc(rand * real((2**buffer_write_data'length - 1))));
      buffer_write_data <= std_logic_vector(to_unsigned(int_rand, buffer_write_data'length));
      buffer_we <= '1';
      buffer_strobe <= '1';
      wait until rising_edge(clk);
      buffer_strobe <= '0';
    end loop;
    wait until rising_edge(clk);
    start <= '1';
    wait until rising_edge(clk);
    start <= '0';
    wait until rising_edge(clk);
    wait until frame_tx_complete = '1';
  end process;

  vis_q_out_gen : for i in vis_q_out'range generate
    vis_q_out(i) <= std_logic(q_out(i - (q_out'high - q_out'low) + 1));
  end generate;

  vis_i_out_gen : for i in vis_i_out'range generate
    vis_i_out(i) <= std_logic(i_out(i - (i_out'high - i_out'low) + 1));
  end generate;

end sim;
