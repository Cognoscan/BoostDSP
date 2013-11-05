--! @file symbolizer_ea.vhd
--! @brief Takes a parallel bus and maps it to symbols
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

entity symbolizer is
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

architecture rtl of symbolizer is

  constant data_buffer_count_high : positive :=
    get_counter_width(data_in'length) - 1;
  signal data_buffer_count : unsigned(data_buffer_count_high downto 0);
  --! Internal buffer containing data to load into symbols.
  signal data_buffer : std_logic_vector(data_in'range);

  --! State of symbol fetching process
  signal symbol_fetcher : std_logic;
  constant symbol_buffer_count_high : positive :=
    get_counter_width(symbol_out'length) - 1;
  signal symbol_buffer_count : unsigned(symbol_buffer_count_high downto 0);
  --! Internal buffer building up next symbol to output
  signal symbol_buffer : std_logic_vector(symbol_out'range);

  signal symbol_ready : std_logic;
  signal symbol_ready_set : std_logic;
  signal symbol_ready_rst : std_logic;

  --! State machine states for buffer_read_proc
  type buffer_read_proc_states is (st_init, st_load_symbol, st_wait_for_read);
  --! State variable for buffer_read_proc
  signal buffer_state : buffer_read_proc_states;

  signal symbol_register : std_logic_vector(symbol_out'range);

begin

  --! Symbol loading process. Slowly clocks data into the symbol buffer from the 
  --! data buffer. When data buffer is empty, the process stops and waits for 
  --! the data_valid to strobe high and load more data into the symbol buffer.
  --!
  --! Controls: busy, buffer_count, data_buffer, symbol_buffer
  buffer_read_proc : process (clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        buffer_state <= st_init;
        data_buffer <= (others => '0');
        symbol_buffer <= (others => '0');
        data_buffer_count <= (others => '0');
        symbol_buffer_count <= (others => '0');
        busy <= '0';
        symbol_ready_set <= '0';
      else
        case buffer_state is
          -- More data required to start buffering
          when st_init =>
            if data_valid = '1' then
              data_buffer <= data_in;
              data_buffer_count <= to_unsigned(data_buffer'length, data_buffer_count'length);
              busy <= '1';
              buffer_state <= st_load_symbol;
            end if;
          -- Slowly move symbol over to output
          when st_load_symbol =>
            -- Out of Data?
            if data_buffer_count = to_unsigned(0, data_buffer_count'length) then
              buffer_state <= st_init;
              busy <= '0';
            -- Data available in data_buffer
            else
              -- symbol_buffer not full?
              if symbol_buffer_count /= to_unsigned(symbol_buffer'length, 
                  symbol_buffer_count'length) then
                symbol_buffer_count <= symbol_buffer_count + 1;
                data_buffer_count <= data_buffer_count - 1;
                symbol_buffer(to_integer(symbol_buffer_count)) <= data_buffer(0);
                data_buffer <= data_buffer srl 1;
              -- symbol_buffer is full
              else
                symbol_ready_set <= '1';
                buffer_state <= st_wait_for_read;
              end if;
            end if;
          -- Wait for buffered symbol to be moved to output
          when st_wait_for_read =>
              symbol_ready_set <= '0';
            if (symbol_ready = '0' and symbol_ready_set = '0') then
              buffer_state <= st_load_symbol;
              symbol_buffer <= (others => '0'); -- Reset symbol_buffer
              symbol_buffer_count <= (others => '0');
            end if;
          when others =>
            buffer_state <= st_init;
        end case;
      end if;
    end if;
  end process;

  --! Sets/resets symbol_ready. Buffer_read_proc sets it, and symbol_fetch_proc 
  --! resets it.
  symbol_ready_proc : process (clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        symbol_ready <= '0';
      else
        if symbol_ready = '1' then
          if symbol_ready_rst = '1' then
            symbol_ready <= '0';
          end if;
        else
          if symbol_ready_set = '1' then
            symbol_ready <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;


  --! Symbol fetching process. When fetch_symbol goes high, the next symbol is 
  --! moved from the symbol buffer into the symbol_out register.
  symbol_fetch_proc : process (clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        symbol_register <= (others => '0');
        symbol_fetcher <= '0';
        symbol_ready_rst <= '0';
      else
        case symbol_fetcher is
          when '0' =>
            if fetch_symbol = '1' then
              symbol_register <= symbol_buffer;
              symbol_fetcher <= '1';
              symbol_ready_rst <= '1';
            end if;
          when '1' =>
            if fetch_symbol = '0' then
              symbol_fetcher <= '0';
              symbol_ready_rst <= '0';
            end if;
          when others =>
            symbol_fetcher <= '0';
        end case;
      end if;
    end if;
  end process;

  symbol_out <= symbol_register;

end rtl;
