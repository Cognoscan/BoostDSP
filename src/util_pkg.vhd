library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.fixed_pkg.all;


package util_pkg is

  --! Unconstrained array of unsigned values
  type unsigned_vector is array (natural range <>) of unsigned;
  --! Unconstrained array of signed values
  type signed_vector is array (natural range <>) of signed;

  --! Unconstrained array of unsigned fixed values
  type ufixed_vector is array (natural range <>) of ufixed;
  --! Unconstrained array of signed fixed values
  type sfixed_vector is array (natural range <>) of sfixed;

  --! Convert real_vector to sfixed_vector
  function to_sfixed_vector(vector_in : real_vector; high, low : integer) return sfixed_vector;

  --! Find maximum of two integers (helper function)
  function max(i,j : integer) return integer;

  --! Reverse the std_logic vectors: x'low -> y'high, etc.
  function reverse(x : std_logic_vector) return std_logic_vector;

  --! Find minimum size of a counter given the maximum count value
  function get_counter_width(x : integer) return integer;

end package;

package body util_pkg is

  --! Convert real_vector to sfixed_vector
  function to_sfixed_vector(vector_in : real_vector; high, low : integer) return sfixed_vector is
    variable vector_out : sfixed_vector(vector_in'range)(high downto low);
  begin
    for i in vector_in'range loop
      vector_out(i) := to_sfixed(vector_in(i), high, low);
    end loop;
    return vector_out;
  end function;

  -- Find maximum of two integers (helper function)
  function max (i,j : integer) return integer is
  begin
    if i > j then return i;
    else return j;
    end if;
  end function;

  --! Reverse the std_logic vectors: x'low -> y'high, etc.
  function reverse(x : std_logic_vector) return std_logic_vector is
    variable y : std_logic_vector(x'range);
  begin
    for i in x'range loop
      y(i) := x(x'high - i);
    end loop;
    return y;
  end function;
  
  --! Find minimum size of a counter given the maximum count value
  function get_counter_width(x : integer) return integer is
  begin
    return integer(ceil(log2(real(x) + 1.0)));
  end function;

end package body;
