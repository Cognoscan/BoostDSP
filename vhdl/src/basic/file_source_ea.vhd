--! @file file_source_ea.vhd
--! @brief Reads fixed-point data from a file.
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

--! Need standard file I/O package
use std.textio.all;

--! Standard IEEE library
library ieee;
use ieee.std_logic_1164.all;

use work.fixed_pkg.all;
use work.util_pkg.all;

--! Reads fixed-point values from a file. Outputs data one line at a time, and 
--! does so on the rising edge of clk, provided that rst is low. When the end of 
--! the file is reached, it loops around to the beginning.
entity file_source is
  generic (
    FILE_NAME : string --! File to read data from
  );
  port (
    clk : in std_logic; --! Clock line
    rst : in std_logic; --! Reset line
    dout : out sfixed --! Fixed-point data output
  );
end entity;

--! Uses Textio to read data line by line from a file. It assumes data is stored 
--! as human-readable real values, separated by newline characters.
architecture sim of file_source is

  file in_file : text open read_mode is FILE_NAME; --! File source

begin

  --! Read data from file on rising clock edge
  read_data : process (clk, rst)
    variable buf : line; --! Text buffer between file input and data
    variable data : real; --! Data temporarily stored as a real
  begin
    if rising_edge(clk) and (rst = '0') then
      -- Reload file if out of data.
      if endfile(in_file) then
        file_close(in_file);
        file_open(in_file, FILE_NAME, read_mode);
      end if;
      readline(in_file, buf); -- Read line by line
      read(buf, data); -- Read string into a real
      dout <= to_sfixed(data ,dout); -- Convert to fixed-point
    end if;
  end process;

end sim;
