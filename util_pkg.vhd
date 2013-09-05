library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package util_pkg is

  -- Find maximum of two integers (helper function)
  function max(i,j : integer) return integer;

  function reverse(x : std_logic_vector) return std_logic_vector;

end package;

package body util_pkg is

  -- Find maximum of two integers (helper function)
  function max (i,j : integer) return integer is
  begin
    if i > j then return i;
    else return j;
    end if;
  end function;

  function reverse(x : std_logic_vector) return std_logic_vector is
    variable y : std_logic_vector(x'range);
  begin
    for i in x'range loop
      y(i) := x(x'high - i);
    end loop;
    return y;
  end function;
  
end package body;
