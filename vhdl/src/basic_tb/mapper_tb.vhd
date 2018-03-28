--! @file mapper_tb.vhd
--! @brief Fixed Mapper testbench
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
use boostdsp.util_pkg.all;
use boostdsp.basic_pkg;

--! Tests the boostdsp.mapper entity.
entity mapper_tb is
end entity;

--! Tests the boostdsp.mapper entity with a 3-bit data vector and map table.
architecture sim of mapper_tb is

--! Half period of clock line
constant clk_hp : time := 1 ns;

signal clk    : std_logic := '0'; --! Clock for UUT
signal rst    : std_logic := '1'; --! Reset for UUT
signal data : unsigned(2 downto 0) := (others => '0'); --! Data into mapper
signal data_std : std_logic_vector(data'range) := (others => '0');
signal sine   : sfixed(1 downto -6); --! Sine output
signal cosine : sfixed(1 downto -6); --! Cosine output

signal vis_sine : signed(7 downto 0);
signal vis_cosine : signed(7 downto 0);

constant map_values_i : real_vector(0 to 7) :=
  ( 1.0, 1.0, 0.0, 1.0, 0.0, -1.0, -1.0, -1.0 );
constant map_values_q : real_vector(0 to 7) :=
  ( 1.0, 0.0, -1.0, -1.0, 1.0, 1.0, -1.0, 0.0 );

begin

  data_std <= std_logic_vector(data);

  uut : basic_pkg.mapper
    generic map (
    map_values_i => map_values_i,
    map_values_q => map_values_q
  )
  port map (
         clk   => clk,
         rst   => rst,
         data  => data_std,
         i_out => cosine,
         q_out => sine 
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

  test_input : process
  begin
    data <= data + 1;
    wait for clk_hp * 2;
  end process;

  vis_sine_gen : for i in vis_sine'range generate
    vis_sine(i) <= std_logic(sine(i - (sine'high - sine'low) + 1));
  end generate;

  vis_cosine_gen : for i in vis_cosine'range generate
    vis_cosine(i) <= std_logic(cosine(i - (cosine'high - cosine'low) + 1));
  end generate;

end sim;
