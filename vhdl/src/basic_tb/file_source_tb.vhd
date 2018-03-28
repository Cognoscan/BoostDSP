--! @file file_source_tb.vhd
--! @brief File Source testbench
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-12-14
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

entity file_source_tb is
  generic (
    FILE_NAME : string := string'("file_source_tb.txt")
  );
end entity file_source_tb;

architecture sim of file_source_tb is

  constant clk_p : time := 10 ns;
  constant clk_hp : time := clk_p  / 2;

  signal clk : std_logic := '0'; --! Clock line
  signal rst : std_logic := '1'; --! Reset line
  signal dout : sfixed(4 downto -9); --! Data output (range -16 to 16)
  signal data_visualized : signed(13 downto 0);

begin

  uut : basic_pkg.file_source
  generic map (
                FILE_NAME => FILE_NAME
              )
  port map (
             clk  => clk,
             rst  => rst,
             dout => dout
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

  data_visualized <= sfixed_as_signed(dout);

end sim;
