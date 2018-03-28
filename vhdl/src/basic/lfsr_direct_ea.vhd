--! @file lfsr_ea.vhd
--! @brief Direct Feedback LFSR implementation
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-11-06
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

--! Standard Library
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! Import necessary local packages
use work.util_pkg.all;

--! Many-to-one Architecture of LFSR
entity lfsr_direct is
  generic (
    INTERNAL_SIZE : positive := 8;    --! Set internal size of LFSR
    SEED          : natural := 1;     --! Choose custom seed of LFSR
    USE_XNOR      : boolean := true;  --! Use XNOR instead of XOR for feedback
    POLY   : std_logic_vector --! Polynomial for LFSR to use 
  );
  port (
    clk : in  std_logic; --! System clock
    rst : in  std_logic; --! System reset
    q   : out std_logic_vector --! Output of LFSR
  );
end entity;

--! Many-to-one Architecture of LFSR
architecture rtl of lfsr_direct is

  --! LFSR full internal register
  signal lfsr_reg : std_logic_vector((INTERNAL_SIZE - 1) downto 0);
  --! Reversed polynomial constant used in direct feedback
  constant reverse_poly : std_logic_vector((INTERNAL_SIZE - 1) downto 0) :=
    reverse(POLY);
  --! Reference to a bad seed of all '1'. Will cause lock-up state.
  constant BAD_SEED : std_logic_vector((INTERNAL_SIZE - 1) downto 0) :=
    (others => '1');

begin
  -- State assumptions first
  assert std_logic_vector(to_unsigned(SEED, INTERNAL_SIZE)) /= BAD_SEED 
    report "Chosen seed will cause LFSR lock-up" 
    severity warning;
  assert INTERNAL_SIZE >= q'length
    report "Internal size must be at least as big as output"
    severity error;
  assert POLY'length = INTERNAL_SIZE
    report "Polynomial length must equal internal register size"
    severity error;
  
  --! Generate LFSR
  data_pipeline : process(clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        lfsr_reg <= std_logic_vector(to_unsigned(SEED, INTERNAL_SIZE));
      else
        -- Many-to-one LFSR
        for i in lfsr_reg'range loop
          if i = lfsr_reg'high then
            lfsr_reg(i) <= xor ((not reverse_poly) or lfsr_reg);
          else
            lfsr_reg(i) <= lfsr_reg(i+1);
          end if;
        end loop;
      end if; -- rst = '1'
    end if; -- rising_edge(clk)
  end process;

  q <= lfsr_reg(q'range);

end rtl;

