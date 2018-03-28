--! @file file_sink_tb.vhd
--! @brief File Sink testbench
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-12-13
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
use ieee.fixed_float_types.all;

library boostdsp;
use boostdsp.fixed_pkg.all;
use boostdsp.basic_pkg;


--! Tests the fixed-point file sink with a cosine generator.
entity file_sink_tb is
  generic (
    FILE_NAME : string := string'("file_sink_tb.txt") --! File to dump to
  );
end entity;

architecture sim of file_sink_tb is

  constant clk_p : time := 10 ns;
  constant clk_hp : time := clk_p / 2;

  signal clk : std_logic := '0'; --! Ssytem clock
  signal rst : std_logic := '1'; --! Reset for system
  signal din : sfixed(1 downto -6); --! Data to dump to file
  signal sine : sfixed(1 downto -6); --! Unused sine output.

  --! Angle to drive trig_table.
  signal angle : ufixed(-1 downto -7) := to_ufixed(0.0, -1, -7);

begin

  --! File Sink to test.
  uut : basic_pkg.file_sink
  generic map (
    FILE_NAME => FILE_NAME
  )
  port map (
    clk => clk,
    rst => rst,
    din => din
  );

  --! Sin & Cos lookup table.
  cosine_test : basic_pkg.trig_table
    port map (
           clk    => clk,
           rst    => rst,
           angle  => angle,
           sine   => sine,
           cosine => din
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

  --! Process to run test.
  test_proc : process
  begin
    wait for clk_p;
    angle <= resize(angle + to_ufixed(1.0/100.0, angle), angle'high, angle'low, 
             fixed_wrap, fixed_truncate); 
  end process;

end sim;
