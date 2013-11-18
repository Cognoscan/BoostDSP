--! @file complex_multiply_sfixed_ea.vhd
--! @brief Complex Multiplier designed around Xilinx XtremeDSP48E.
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-11-13
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
use ieee.numeric_std.all;

library boostdsp;
use boostdsp.fixed_pkg.all;


entity complex_multiply_sfixed is
  port (
    clk : in std_logic; --! System clock
    rst : in std_logic; --! Reset signal
    a_r : in sfixed; --! Real component of A
    a_i : in sfixed; --! Imaginary component of A
    b_r : in sfixed; --! Real component of B
    b_i : in sfixed; --! Imaginary component of B
    c_r : out sfixed; --! Real component of C
    c_i : out sfixed  --! Imaginary component of C
  );
end entity;

--! Uses 3 XtremeDSP48E blocks to perform a complex multiply.
--!
--! @dot
--! digraph {
--!   rankdir = LR;
--!
--!   a_r_d1 [label="D"];
--!   a_i_d1 [label="D"];
--!   b_r_d1 [label="D"];
--!   b_r_d2 [label="D"];
--!   a_rmi  [label="-"];
--!   a_rmi_d [label="D"];
--!   mult1 [label="*"];
--!   mult1_d [label="*"];
--!   c_r_add [label="+"];
--!   c_r_d [label="D"];
--!
--!   b_rmi [label="-"];
--!   b_rmi_d [label="D"];
--!   a_i_delay [label="D"];
--!   mult2 [label="*"];
--!   mult2_d [label="D"];
--!   mult2_d2 [label="D"];
--!
--!   a_r_d2 [label="D"];
--!   a_i_d2 [label="D"];
--!   b_i_d1 [label="D"];
--!   b_i_d2 [label="D"];
--!   a_rpi  [label="+"];
--!   a_rpi_d [label="D"];
--!   mult3 [label="*"];
--!   mult3_d [label="*"];
--!   c_i_add [label="+"];
--!   c_i_d [label="D"];
--!
--!   a_r -> a_r_d1 -> a_rmi -> a_rmi_d -> mult1 -> mult1_d -> c_r_add -> c_r_d;
--!   a_i -> a_i_d1 -> a_rmi;
--!   b_r -> b_r_d1 -> b_r_d2 -> mult1;
--!
--!   b_r -> b_rmi -> b_rmi_d -> mult2 -> mult2_d -> mult2_d2;
--!   b_i -> b_rmi;
--!   a_i -> a_i_delay -> mult2;
--!
--!   mult2_d2 -> c_r_add;
--!   mult2_d2 -> c_i_add;
--!
--!   a_r -> a_r_d2 -> a_rpi -> a_rpi_d -> mult3 -> mult3_d -> c_i_add -> c_i_d;
--!   a_i -> a_i_d2 -> a_rpi;
--!   b_i -> b_i_d1 -> b_i_d2 ->mult3;
--!   
--!   c_r_d -> c_r;
--!   c_i_d -> c_i;
--!
--! }
--!
--! @enddot
--!

architecture rtl of complex_multiply_sfixed is


  signal a_r_delay1 : sfixed(a_r'range);
  signal a_i_delay1 : sfixed(a_i'range);
  signal b_r_delay1 : sfixed(b_r'range);
  signal b_r_delay2 : sfixed(b_r'range);
  signal a_r_minus_i : sfixed(sfixed_high(a_r,'-',a_i) downto 
    sfixed_low(a_r,'-',a_i));
  signal mult1 : sfixed(sfixed_high(a_r_minus_i,'*',b_r) downto
    sfixed_low(a_r_minus_i,'*',b_r));

  signal a_r_delay2 : sfixed(a_r'range);
  signal a_i_delay2 : sfixed(a_i'range);
  signal b_i_delay1 : sfixed(b_i'range);
  signal b_i_delay2 : sfixed(b_i'range);
  signal a_r_plus_i : sfixed(sfixed_high(a_r,'+',a_i) downto 
    sfixed_low(a_r,'+',a_i));
  signal mult3 : sfixed(sfixed_high(a_r_plus_i,'*',b_i) downto
    sfixed_low(a_r_plus_i,'*',b_i));

begin

end rtl;
