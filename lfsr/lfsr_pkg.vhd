library ieee;
use ieee.std_logic_1164.all;
 
package lfsr_pkg is
  function Maximal_Polynomial(size : positive) return std_logic_vector;
end package;

package body lfsr_pkg is
  function Maximal_Polynomial(size : positive) return std_logic_vector is
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


