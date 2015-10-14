--! @file cordic_polar_ea.vhd
--! @brief Converts rectangular complex values to polar complex values.
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-12-18
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

--! Takes in complex data in rectangular format and calculates the magnitude and 
--! phase from them (giving polar form of the complex number). The phase_out 
--! angle is normalized to be from 0 to 1. To get the phase in radians, multiply 
--! it by 2*pi.
--!
--! For explanation of the CORDIC algorithm, refer to Wikipedia, DSP Guru, or 
--! Ray Andraka's paper:
--!
--! - [Wikipedia](http://en.wikipedia.org/wiki/CORDIC)
--! - [DSP Guru](http://www.dspguru.com/dsp/faqs/cordic)
--! - [Ray Andraka](http://www.andraka.com/cordic.htm)
--!
entity cordic_polar is
  generic (
    NUM_STAGES : positive := 5
  );
  port (
    clk       : in std_logic; --! Clock line
    rst       : in std_logic; --! Reset line
    i_in      : in sfixed;    --! In-phase (real) data
    q_in      : in sfixed;    --! Quadrature (imaginary) data
    mag_out   : out sfixed;   --! Magnitude Output
    phase_out : out ufixed   --! Phase Output
  );
end cordic_polar;

architecture rtl of cordic_polar is

  function phase_shift_calc(stages, high, low : integer) return ufixed_vector is
    variable atan_value : real;
    variable table : ufixed_vector(0 to (stages-1))(high downto low);
  begin
    for i in 0 to (stages-1) loop
      atan_value := arctan(2**(real(i)));
      table(i) := to_ufixed(atan_value, high, low);
    end loop;
    return table;
  end function;


  --! Maximum possible bit of working register. 
  constant calc_high : integer := maximum(i_in'high+1, q_in'high+1);
  --! Minimum bit of working register
  constant calc_low : integer := minimum(i_in'low+1, q_in'low+1);

  --! Phase shift Look-up table
  constant phase_shift : ufixed_vector(0 to NUM_STAGES-1)(phase_out'range) :=
    phase_shift_calc(NUM_STAGES, phase_out'high, phase_out'low);
  --! Magnitude scaling
  constant scale_factor : sfixed(calc_high downto calc_low) :=
    to_sfixed(1.0, calc_high, calc_low);

  --! Working real magnitude
  signal i_calc : sfixed_vector(0 to NUM_STAGES-1)(calc_high downto calc_low);
  --! Working imag magnitude
  signal q_calc : sfixed_vector(0 to NUM_STAGES-1)(calc_high downto calc_low);
  --! Working phase register vector
  signal phase_calc : ufixed_vector(0 to NUM_STAGES-1)(phase_out'range);

begin

  data_pipeline : process(clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        i_calc <= (others => to_sfixed(0, i_calc'element'high,i_calc'element'low));
        q_calc <= (others => to_sfixed(0, q_calc'element'high,q_calc'element'low));
        phase_calc <= (others => to_ufixed(0,
                      phase_calc'element'high, phase_calc'element'low));
        mag_out <= to_sfixed(0, mag_out);
        phase_out <= to_ufixed(0, phase_out);
      else
        if i_in < 0 then
          i_calc(0) <= resize(-i_in, i_calc(0));
          q_calc(0) <= resize(-q_in, q_calc(0));
          phase_calc(0) <= to_ufixed(0.5, phase_calc(0));
        else
          i_calc(0) <= resize(i_in, i_calc(0));
          q_calc(0) <= resize(q_in, q_calc(0));
          phase_calc(0) <= to_ufixed(0, phase_calc(0));
        end if;
        
        for i in 0 to (NUM_STAGES-2) loop
          if q_calc(i) < 0 then
            i_calc(i+1) <= i_calc(i) - (q_calc(i) sra i);
            q_calc(i+1) <= q_calc(i) + (i_calc(i) sra i);
            phase_calc(i+1) <= phase_calc(i) - phase_shift(i);
          else
            i_calc(i+1) <= i_calc(i) + (q_calc(i) sra i);
            q_calc(i+1) <= q_calc(i) - (i_calc(i) sra i);
            phase_calc(i+1) <= phase_calc(i) + phase_shift(i);
          end if;
        end loop;

        mag_out <= resize(scale_factor * i_calc(i_calc'high),
                   mag_out'high, mag_out'low);
        phase_out <= phase_calc(phase_calc'high);
      end if; -- rst
    end if; -- clk
  end process;

end rtl;

