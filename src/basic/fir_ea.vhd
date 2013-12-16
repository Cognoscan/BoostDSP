--! @file fir_ea.vhd
--! @brief Pipelined FIR filter
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-12-16
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
use work.util_pkg.all;

--! Pipelined FIR filter. Can be configured to be a symmetric filter, and takes 
--! in coefficients as it runs. The upper and lower bits of the fixed-point 
--! accumulators must be set by the user. The recommended values of these are 
--! vendor- and application-dependent, and thus cannot be calculated within this 
--! entity.
--!
--! @bug Symmetric option and even option don't work.
entity fir is
  generic (
    SYMMETRIC : boolean := false; --! Symmetric filter
    EVEN      : boolean := false; --! Even or odd number of total coefficients
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
end entity fir;

architecture rtl of fir is

  signal in_line : sfixed_vector(coeff'range)(din'range);
  signal delay0  : sfixed_vector(coeff'range)(din'range);

  signal coeff_reg : sfixed_vector(coeff'range)(coeff'element'range);

  signal mul_reg : sfixed_vector(coeff'range)(UPPER_BIT downto LOWER_BIT);

  signal add_reg : sfixed_vector(coeff'range)(UPPER_BIT downto LOWER_BIT);

  signal symmetric_delay : sfixed_vector(coeff'range)(din'range);

  signal symmetric_input : sfixed_vector(coeff'range)(din'range);

  signal preadd_reg : sfixed_vector(coeff'range)(
    sfixed_high(din'high, din'low, '+', din'high, din'low) downto
    sfixed_low(din'high, din'low, '+', din'high, din'low));

begin

  pipeline : process(clk,rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        -- Zero everything out
        in_line <= (others => to_sfixed(0,
                   in_line'element'high, in_line'element'low));
        delay0 <= (others => to_sfixed(0,
                   delay0'element'high, delay0'element'low));
        coeff_reg <= (others => to_sfixed(0,
                   coeff_reg'element'high, coeff_reg'element'low));
        mul_reg <= (others => to_sfixed(0,
                   mul_reg'element'high, mul_reg'element'low));
        add_reg <= (others => to_sfixed(0,
                   add_reg'element'high, add_reg'element'low));
        if SYMMETRIC then
          symmetric_delay <= (others => to_sfixed(0,
                     symmetric_delay'element'high, symmetric_delay'element'low));
          symmetric_input <= (others => to_sfixed(0,
                     symmetric_input'element'high, symmetric_input'element'low));
        end if;
      else
        for i in coeff'range(1) loop
          -- Input data pipeline
          if i = 0 then
            in_line(i) <= din; -- Feed data in to delay line
          else
            in_line(i) <= delay0(i-1); -- Build up delay line registers
          end if;
          delay0(i) <= in_line(i); -- Delay input by 1
          coeff_reg(i) <= coeff(i); -- Register all coefficients

          -- Multiplier & preadder are different depending on whether the filter 
          -- is symmetric or not
          if SYMMETRIC = true then
            -- Delay line for symmetric data
            if i = 0 then
              symmetric_delay(i) <= din;
            else
              symmetric_delay(i) <= symmetric_delay(i-1);
            end if;
            -- Preadder for symmetric filter
            symmetric_input(i) <= symmetric_delay(i);
            preadd_reg(i) <= delay0(i) + symmetric_input(coeff'high(1));

            -- Multiply data by coefficients
            mul_reg(i) <= resize(preadd_reg(i) * coeff_reg(i),
                          UPPER_BIT, LOWER_BIT);
          else
            -- Multiply data by coefficients
            mul_reg(i) <= resize(delay0(i) * coeff_reg(i),
                          UPPER_BIT, LOWER_BIT);
          end if;

          -- Adders
          if i = 0 then
            -- First adder has no previous adder output
            add_reg(i) <= resize(mul_reg(i),
                          UPPER_BIT, LOWER_BIT);
          else
            -- Build up adder chain
            add_reg(i) <= resize(mul_reg(i) + add_reg(i-1),
                          UPPER_BIT, LOWER_BIT);
          end if;
        end loop;
      end if;
    end if;
  end process;

  --! Final output is output from highest adder
  dout <= add_reg(add_reg'high(1))(dout'high downto dout'low);

end rtl;
