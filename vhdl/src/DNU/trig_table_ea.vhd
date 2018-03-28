--! @file trig_table_ea.vhd
--! @brief sin/cos lookup table generator
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-09-30
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
use work.fixed_pkg.all;

--! @brief Sin & Cos lookup table
--! @details 
--! Outputs cos(2*pi*angle) and sin(2*pi*angle), where 0 <= angle < 1.
entity trig_table is
  port (
    clk : in std_logic;
    rst : in std_logic;
    angle : in ufixed
  );
end entity;

architecture rtl of trig_table is
begin

end rtl;
