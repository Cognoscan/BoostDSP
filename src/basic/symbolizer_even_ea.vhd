--! @file symbolizer_even_ea.vhd
--! @brief Takes a parallel bus and maps it to symbols
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-11-05
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

--! Takes parallel data and outputs it as shorter length data (symbols), for use 
--! in passing to a symbol mapper. This symbolizer is built such that the length 
--! of the parallel data should be a multiple of the symbol data length. If the 
--! system does not adhere to this, then the entity "symbolizer" should be used 
--! instead.
--!
--! When driving the fetch_symbol signal, allow at least three clock cycles 
--! between each rising edge.
--!
--! Both data_valid and fetch_symbol are expected to be single clock cycle 
--! strobes.
entity symbolizer_even is
  port (
    clk : in std_logic; --! System clock
    rst : in std_logic; --! System reset
    data_in : in std_logic_vector; --! Incoming data
    busy : out std_logic; --! Busy (cannot fetch data)
    data_valid : in std_logic; --! Strobe when data_in valid
    fetch_symbol : in std_logic; --! System fetching next symbol
    symbol_out : out std_logic_vector --! Outgoing symbol
  );
end entity;

architecture rtl of symbolizer_even is
  
  signal data_buffer : std_logic_vector(data_in'range);
  signal symbol_buffer : std_logic_vector(symbol_out'range);

  constant symbols_per_chunk : positive := data_in'length / symbol_out'length;

  constant symbol_counter_length : positive := 
    get_counter_width(symbols_per_chunk);

  signal symbol_counter : unsigned((symbol_counter_length - 1) downto 0);

begin
  -- Always state assumptions first
  assert data_in'length mod symbol_out'length = 0
    report "data_in's length must be a multiple of symbol_out's length"
    severity error;

  symbol_out <= symbol_buffer;

  data_pipeline : process (clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        symbol_buffer <= (others => '0');
        data_buffer <= (others => '0');
        symbol_counter <= to_unsigned(symbols_per_chunk, symbol_counter'length);
        busy <= '0';
      else
        -- Pull symbols as required
        if fetch_symbol = '1' then
          -- The next symbol is unfetchable. Supply with 0.
          if symbol_counter = to_unsigned(symbols_per_chunk, 
          symbol_counter'length) then
            busy <= '0';
            symbol_buffer <= (others => '0');
          else
            busy <= '1';
            symbol_buffer <= data_buffer(((to_integer(symbol_counter) + 1)
                             * symbol_out'length - 1) downto 
                             to_integer(symbol_counter) * symbol_out'length);
            symbol_counter <= symbol_counter + 1;
          end if;
        else
          -- The next symbol is unfetchable. More data needed.
          if symbol_counter = to_unsigned(symbols_per_chunk, 
          symbol_counter'length) then
            busy <= '0';
            if data_valid = '1' then
              data_buffer <= data_in;
              busy <= '1';
              symbol_counter <= to_unsigned(0, symbol_counter'length);
            end if;
          end if; -- unfetchable?
        end if; -- symbol fetching
      end if; -- rst
    end if; -- clk
  end process;

end rtl;
