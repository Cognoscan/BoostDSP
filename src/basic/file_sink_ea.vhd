--! @file file_sink_ea.vhd
--! @brief Writes fixed-point data to a file.
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

--! Need standard file I/O package
use std.textio.all;

--! Standard IEEE library
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.util_pkg.all;

--! Dumps fixed-point values to a file. Outputs data to the file one line at 
--! a time, and does so on the rising edge of clk, provided that rst is low.
entity file_sink is
  generic (
    FILE_NAME : string --! File name to write to
  );
  port (
    clk : in std_logic; --! Clock line
    rst : in std_logic; --! Reset line
    din : in sfixed --! Data to read
  );
end entity;

--! Uses Textio to write data line by line to a file. It stores data as 
--! human-readable real values, separated by newline characters.
architecture sim of file_sink is
  
  file out_file : text open write_mode is FILE_NAME; --! File sink

begin

  --! Write file output on rising clock edge
  write_output : process (clk, rst)
    variable  buf : line; --! Text buffer between data and file output
  begin
    if rising_edge(clk) and (rst = '0') then
      write(buf, to_real(din));
      writeline(out_file, buf);
    end if;
  end process;

end sim;
