--! @file basic_pkg.vhd
--! @brief Package containing all basic elements in BoostDSP
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

use work.fixed_pkg.all;
use work.util_pkg.all;

package basic_pkg is

--! Linear Feedback shift register using direct-type feedback.
--! The direct feedback feeds the result of the polynomial into the highest bit. 
--! Usethe maximal_polynomial function for easy generation of maximal length 
--! polynomials up to 32 bits long.
  component lfsr_direct is
  generic (
    INTERNAL_SIZE : positive;    --! Set internal size of LFSR
    SEED          : natural;     --! Choose custom seed of LFSR
    USE_XNOR      : boolean := true;  --! Use XNOR instead of XOR for feedback
    POLY   : std_logic_vector --! Polynomial for LFSR to use 
  );
  port (
    clk : in  std_logic; --! System clock
    rst : in  std_logic; --! System reset
    q   : out std_logic_vector --! Output of LFSR
  );
  end component;

--! Linear Feedback shift register. Uses Galois-type feedback.
--! The galois feedback places the XOR/XNOR gates into the shift register path. 
--! Use the maximal_polynomial function for easy generation of maximal length 
--! polynomials up to 32 bits long.
  component lfsr_galois is
  generic (
    INTERNAL_SIZE : positive;    --! Set internal size of LFSR
    SEED          : natural;     --! Choose custom seed of LFSR
    USE_XNOR      : boolean := true;  --! Use XNOR instead of XOR for feedback
    POLY   : std_logic_vector --! Polynomial for LFSR to use 
  );
  port (
    clk : in  std_logic; --! System clock
    rst : in  std_logic; --! System reset
    q   : out std_logic_vector --! Output of LFSR
  );
  end component;

--! Sin & Cos lookup table.
--! Outputs cos(2*pi*angle) and sin(2*pi*angle), where 0 <= angle < 1.
  component trig_table is
    port (
           clk    : in std_logic;
           rst    : in std_logic;
           angle  : in ufixed;
           sine   : out sfixed;
           cosine : out sfixed
         );
  end component;

  component mapper is
    generic (
    map_values_i : real_vector;
    map_values_q : real_vector
  );
  port (
         clk   : in std_logic;
         rst   : in std_logic;
         data  : in std_logic_vector;
         i_out : out sfixed;
         q_out : out sfixed
       );
  end component;

  component symbolizer is
    port (
           clk          : in std_logic; --! System clock
           rst          : in std_logic; --! System reset
           data_in      : in std_logic_vector; --! Incoming data
           busy         : out std_logic; --! Busy (cannot fetch data)
           data_valid   : in std_logic; --! Strobe when data_in valid
           fetch_symbol : in std_logic; --! System fetching next symbol
           symbol_out   : out std_logic_vector --! Outgoing symbol
         );
  end component;

  component symbolizer_even is
    port (
           clk          : in std_logic; --! System clock
           rst          : in std_logic; --! System reset
           data_in      : in std_logic_vector; --! Incoming data
           busy         : out std_logic; --! Busy (cannot fetch data)
           data_valid   : in std_logic; --! Strobe when data_in valid
           fetch_symbol : in std_logic; --! System fetching next symbol
           symbol_out   : out std_logic_vector --! Outgoing symbol
         );
  end component;

  --! Dumps fixed-point values to a file. Outputs data to the file one line at 
  --! a time, and does so on the rising edge of clk, provided that rst is low.
  component file_sink is
    generic (
    FILE_NAME : string --! File name to write to
  );
  port (
         clk : in std_logic; --! Clock line
         rst : in std_logic; --! Reset line
         din : in sfixed --! Data to read
       );
  end component;

  --! Reads fixed-point values from a file. Outputs data one line at a time, and 
  --! does so on the rising edge of clk, provided that rst is low. When the end of 
  --! the file is reached, it loops around to the beginning.
  component file_source is
    generic (
    FILE_NAME : string --! File to read data from
  );
  port (
         clk : in std_logic; --! Clock line
         rst : in std_logic; --! Reset line
         dout : out sfixed --! Fixed-point data output
       );
  end component;

  --! Pipelined FIR filter. Can be configured to be a symmetric filter, and takes 
  --! in coefficients as it runs. The upper and lower bits of the fixed-point 
  --! accumulators must be set by the user. The recommended values of these are 
  --! vendor- and application-dependent, and thus cannot be calculated within this 
  --! entity.
  component fir is
    generic (
    SYMMETRIC : boolean; --! Symmetric filter
    EVEN      : boolean; --! Even or odd number of total coefficients
    UPPER_BIT : integer; --! Upper bit of accumulator
    LOWER_BIT : integer  --! Lower bit of accumulator
  );
  port (
         clk : in std_logic; --! Clock line
         rst : in std_logic; --! Reset line
         coeff : in sfixed_vector; --! Coefficient vector
         din : in sfixed; --! Data into FIR filter
         dout : out sfixed --! Filtered data
       );
  end component;

  constant bpsk_i : real_vector(0 to 1) := ( 1.0, -1.0 );
  constant bpsk_q : real_vector(0 to 1) := ( 1.0, -1.0 );

  constant qpsk_i : real_vector(0 to 3) := ( -1.0, -1.0, 1.0, 1.0 );
  constant qpsk_q : real_vector(0 to 3) := ( -1.0, 1.0, -1.0, 1.0 );

  constant eight_psk_i : real_vector(0 to 7) :=
    ( -0.7071, -1.0, 0.0, -0.7071, 0.0, 0.7071, 0.7071, 1.0 );
  constant eight_psk_q : real_vector(0 to 7) :=
    ( -0.7071, 0.0, 1.0, 0.7071, -1.0, -0.7071, 0.7071, 0.0 );

  constant qam16_i : real_vector(0 to 15) := (
        -1.0,     -1.0,     -1.0,     -1.0,
    (-1.0/3), (-1.0/3), (-1.0/3), (-1.0/3),
     (1.0/3),  (1.0/3),  (1.0/3),  (1.0/3),
         1.0,      1.0,      1.0,    1.0 );

  constant qam16_q : real_vector(0 to 15) := (
    -1.0, (-1.0/3), 1.0, (1.0/3),
    -1.0, (-1.0/3), 1.0, (1.0/3),
    -1.0, (-1.0/3), 1.0, (1.0/3),
    -1.0, (-1.0/3), 1.0, (1.0/3));

  function maximal_polynomial(size : positive) return std_logic_vector;

end package;

package body basic_pkg is

  function maximal_polynomial(size : positive) return std_logic_vector is
    variable polynomial : std_logic_vector((size - 1) downto 0);
  begin
  -- Polynomials taken from Xilinx App Note XAPP 052. Covers up to 168 bits.
  -- Only the first 32 maximal-length polynomials are recorded here.
  -- Retrieved on Aug 14, 2013 from 
  -- http://www.xilinx.com/support/documentation/application_notes/xapp052.pdf
  -- TODO: Add all polynomials up to 168 bits, and verify completeness.
    case size is
      when  1 => polynomial := "1";
      when  2 => polynomial := "11";
      when  3 => polynomial := "110";
      when  4 => polynomial := "1100";
      when  5 => polynomial := "10100";
      when  6 => polynomial := "110000";
      when  7 => polynomial := "1100000";
      when  8 => polynomial := "10111000";
      when  9 => polynomial := "100010000";
      when 10 => polynomial := "1001000000";
      when 11 => polynomial := "10100000000";
      when 12 => polynomial := "100000101001";
      when 13 => polynomial := "1000000001101";
      when 14 => polynomial := "10000000010101";
      when 15 => polynomial := "110000000000000";
      when 16 => polynomial := "1101000000001000";
      when 17 => polynomial := "10010000000000000";
      when 18 => polynomial := "100010000000000000";
      when 19 => polynomial := "1000000000000100011";
      when 20 => polynomial := "10010000000000000000";
      when 21 => polynomial := "101000000000000000000";
      when 22 => polynomial := "1100000000000000000000";
      when 23 => polynomial := "10010000000000000000000";
      when 24 => polynomial := "111000010000000000000000";
      when 25 => polynomial := "1001000000000000000000000";
      when 26 => polynomial := "10000000000000000000100011";
      when 27 => polynomial := "100000000000000000000010011";
      when 28 => polynomial := "1001000000000000000000000000";
      when 29 => polynomial := "10100000000000000000000000000";
      when 30 => polynomial := "100000000000000000000000101001";
      when 31 => polynomial := "1001000000000000000000000000000";
      when 32 => polynomial := "10000000001000000000000000000011";
      when others =>
        polynomial := (others => '0'); 
        assert false report "No polynomial for given size" severity error;
    end case;
    return polynomial;
  end function;

end package body;
