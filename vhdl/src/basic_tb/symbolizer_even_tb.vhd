--! @file symbolizer_even_tb.vhd
--! @brief Symbolizer block testbench
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-11-05
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

entity symbolizer_even_tb is
end entity symbolizer_even_tb;

architecture rtl of symbolizer_even_tb is

  constant clk_hp : time := 1 ns;

signal clk          : std_logic := '1';
signal rst          : std_logic := '1';
signal data_in      : unsigned(15 downto 0) := (others => '0');
signal data_in_std  : std_logic_vector(data_in'range) := (others => '0');
signal busy         : std_logic;
signal data_valid   : std_logic := '0';
signal fetch_symbol : std_logic := '0';
signal symbol_out   : std_logic_vector(3 downto 0) := (others => '0');

begin

  data_in_std <= std_logic_vector(data_in);

  uut : basic_pkg.symbolizer_even
    port map (
           clk          => clk,
           rst          => rst,
           data_in      => data_in_std,
           busy         => busy,
           data_valid   => data_valid,
           fetch_symbol => fetch_symbol,
           symbol_out   => symbol_out
         );

  clk_proc : process
  begin
    wait for clk_hp;
    clk <= not clk;
  end process;

  rst_proc : process
  begin
    wait for clk_hp*4;
    rst <= '0';
  end process;

  fetch_symbols : process
  begin
    wait for clk_hp*4;
    while(true) loop
      wait for (clk_hp*2)*3;
      fetch_symbol <= '1';
      wait for (clk_hp*2);
      fetch_symbol <= '0';
    end loop;
  end process;

  send_data : process
  begin
    wait for clk_hp*4;
    if busy = '0' then
      data_in <= data_in + 1;
      data_valid <= '1';
      wait for clk_hp*2;
      data_valid <= '0';
    end if;
  end process;

end rtl;
