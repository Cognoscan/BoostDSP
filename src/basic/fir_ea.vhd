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
--! If using the symmetric option, make sure to correctly set whether there is 
--! an even or odd **total** number of coefficients. The entity will not function as 
--! expected otherwise.
--!
--! Example: 64-tap filter can be described with 32 coefficients if it is 
--! symmetric. Set EVEN to true so that the entity knows it was originally 
--! a 64-tap filter.
--!
--! Example: 63-tap filter can also be described with 32 coefficients if it is 
--! symmetric. Set EVEN to false so that the entity knows it was originally 
--! a 63-tap filter, and not a 64-tap.
--!
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

  signal symmetric_delay : sfixed_vector(0 to (coeff'high * 2 + 1))(din'range);

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
      else
        for i in coeff'range loop
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
          if SYMMETRIC then
            if ((not EVEN) and (i = coeff'high)) then
              preadd_reg(i) <= resize(delay0(i),
                               preadd_reg'element'high,
                               preadd_reg'element'low);
            else
              preadd_reg(i) <= delay0(i) + symmetric_input(i);
            end if;
            

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

  symmetric_delay_pipeline_gen : if SYMMETRIC generate
    symmetric_delay_pipeline : process(clk, rst)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          symmetric_delay <= (others => to_sfixed(0,
                             symmetric_delay'element'high,
                             symmetric_delay'element'low));
          symmetric_input <= (others => to_sfixed(0,
                             symmetric_input'element'high,
                             symmetric_input'element'low));
        else
          for i in symmetric_delay'range loop
            if i = 0 then
              symmetric_delay(i) <= din;
            else
              symmetric_delay(i) <= symmetric_delay(i - 1);
            end if;
          end loop;
          for i in symmetric_input'range loop
            if EVEN then
              symmetric_input(i) <= symmetric_delay(symmetric_delay'high);
            else
              symmetric_input(i) <= symmetric_delay(symmetric_delay'high-1);
            end if;
          end loop;
        end if; -- rst
      end if; -- clk
    end process; -- pipeline
  end generate; -- generate

  --! Final output is output from highest adder
  dout <= add_reg(add_reg'high(1))(dout'high downto dout'low);

end rtl;
