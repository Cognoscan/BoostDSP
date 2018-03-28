--! @file frame_tx_ea.vhd
--! @brief frame-based transmitter
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

--! Local version of the fixed point package
use work.fixed_pkg.all;
--! Basic design elements
use work.basic_pkg;

--! Creates a buffer that can be read and written to, and provides functionality 
--! to convert the buffer into a series of symbols. It does *not* map the 
--! symbols or generate any kind of waveform.
--! 
--! The frame buffer is addressable by frame_addr. The buffer is sized so that 
--! every possible address exists in the buffer (so buffer size is 
--! 2^frame_addr'length).
--!
--! Frame_tx will iterate through the buffer from 0 to frame_size to create the 
--! symbols after the start line has been strobed high. It can be stopped early 
--! by strobing the abort line high. Once it is finished, frame_tx_complete is 
--! asserted. The frame_tx_complete line is high so long as it is not 
--! transmitting symbols.
--!
--! Finally, when transmitting symbols, frame_tx will dwell on each symbol for 
--! a set number of clock cycles. The number of clock cycles is set by 
--! clks_per_symbol.
entity frame_tx is
  port (
    clk               : in std_logic; --! System clock
    rst               : in std_logic; --! System reset
    frame_size        : in unsigned; --! Size of frame to transmit
    clks_per_symbol   : in unsigned; --! Clock cycles per symbol transmitted
    start             : in std_logic; --! Strobe high to start transmitting.
    abort             : in std_logic; --! Strobe high to abort transmitting.
    frame_tx_complete : out std_logic; --! High when not transmitting.
    buffer_addr       : in std_logic_vector; --! Address to read/write to.
    buffer_we         : in std_logic; --! High when write, low when read.
    buffer_write_data : in std_logic_vector; --! Data to write.
    buffer_read_data  : out std_logic_vector; --! Data read from address.
    buffer_strobe     : in std_logic; --! Strobe high to cycle bus.
    buffer_done       : out std_logic; --! Strobe high when read/write complete.
    symbol_out        : out std_logic_vector --! Symbol output
  );
end entity;

architecture rtl of frame_tx is

  --! The frame buffer std_logic_vector array type
  type frame_buffer_type is array ((2**buffer_addr'length-1) downto 0) of
    std_logic_vector(buffer_write_data'range);
  --! The frame buffer. Initialized to 0 on configuration of device.
  signal frame_buffer : frame_buffer_type := (others => (others => '0'));

  --! Register holding data read back from frame buffer
  signal buffer_read_data_internal : std_logic_vector(buffer_read_data'range);

  --! Stores current address of data moving to symbolizer.
  signal out_counter : unsigned(frame_size'range);

  --! Counter to drive fetch_symbol
  signal symbol_counter : unsigned(clks_per_symbol'range);

  --! Data to write to symbolizer
  signal data_to_symbolizer : std_logic_vector(buffer_write_data'range);
  --! Busy signal from symbolizer
  signal busy : std_logic;
  --! Data valid signal to symbolizer
  signal data_valid : std_logic;
  --! Fetch_symbol signal to symbolizer, strobed based on clks_per_symbol
  signal fetch_symbol : std_logic;

  --! Internal signal is high when transmitting. Used to track state of frame_tx 
  --! within the symbolizer_interface process.
  signal active_tx : std_logic;

begin
  -- Verify assumptions first
  assert buffer_write_data'length = buffer_read_data'length
    report "Write bus and read bus not same length"
    severity error;
  assert frame_size'length = buffer_addr'length
    report "frame_size cannot be full size of transmit buffer"
    severity error;

    -- Create symbolizer. 
    make_symbolizer_even : if (buffer_write_data'length mod symbol_out'length) 
    = 0 generate
      symbolizer_1 : basic_pkg.symbolizer_even
      port map(
                clk          => clk,
                rst          => rst,
                data_in      => data_to_symbolizer,
                busy         => busy,
                data_valid   => data_valid,
                fetch_symbol => fetch_symbol,
                symbol_out   => symbol_out
              );
    end generate;
    make_symbolizer : if (buffer_write_data'length mod symbol_out'length) 
    /= 0 generate
      symbolizer_1 : basic_pkg.symbolizer
      port map(
                clk          => clk,
                rst          => rst,
                data_in      => data_to_symbolizer,
                busy         => busy,
                data_valid   => data_valid,
                fetch_symbol => fetch_symbol,
                symbol_out   => symbol_out
              );
    end generate;

    --! Interface for reading/writing to frame buffer. Very straightforward, and 
    --! takes one cycle to read/write. It just checks for buffer_strobe and 
    --! either reads or writes depending on buffer_we.
    buffer_interface : process(clk, rst)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          buffer_read_data_internal <= (others => '0');
          buffer_done <= '1';
        else
          buffer_done <= '0';
          -- Only take action when the bus is strobed (cycled).
          if buffer_strobe = '1' then
            buffer_done <= '1';
            if buffer_we = '1' then
              frame_buffer(to_integer(unsigned(buffer_addr))) <= 
                buffer_write_data;
            else
              buffer_read_data_internal <= 
                frame_buffer(to_integer(unsigned(buffer_addr)));
            end if; -- read/write check
          end if; -- strobe check
        end if; -- rst
      end if; -- clk
    end process;

    buffer_read_data <= buffer_read_data_internal;

    --! Interface for providing data to the symbolizer
    symbolizer_interface : process(clk, rst)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          data_valid <= '0';
          active_tx <= '0';
          out_counter <= to_unsigned(0, out_counter'length);
          data_to_symbolizer <= (others => '0');
        else
          data_valid <= '0';
          -- Actively transmitting?
          if active_tx = '1' then
            -- Load next whenever symbolizer not busy
            if busy = '0' and data_valid = '0' then
              -- Abort / all data transmitted?
              if abort = '1' or out_counter = (frame_size + 1) then
                active_tx <= '0';
                out_counter <= to_unsigned(0, out_counter'length);
              else
                out_counter <= out_counter + 1;
                data_valid <= '1';
                data_to_symbolizer <= frame_buffer(to_integer(out_counter));
              end if;
            end if;
          else
            -- Wait for start indicator
            if start = '1' then
              active_tx <= '1';
              out_counter <= out_counter + 1;
              data_valid <= '1';
              data_to_symbolizer <= frame_buffer(to_integer(out_counter));
            end if;
          end if; -- active_tx
        end if; -- rst
      end if; -- clk
    end process;

    --! Fetches symbols from the symbolizer every clks_per_symbol by using 
    --! a counter. This can run constantly.
    symbol_fetcher : process (clk, rst)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          fetch_symbol <= '0';
          symbol_counter <= to_unsigned(1, symbol_counter'length);
        else
          if symbol_counter = clks_per_symbol then
            symbol_counter <= to_unsigned(1, symbol_counter'length);
            fetch_symbol <= '1';
          else
            symbol_counter <= symbol_counter + 1;
            fetch_symbol <= '0';
          end if; -- counter
        end if; -- rst
      end if; -- clk
    end process;

    --! Frame_tx_complete when active_tx = 0 AND the last of the data has been 
    --! turned into symbols AND the last symbol has been active for 
    --! clks_per_symbol clock cycles.
    complete_indicate : process (clk, rst)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          frame_tx_complete <= '1';
        else
          if frame_tx_complete = '0' then
            if active_tx = '0' and fetch_symbol = '1' then
              frame_tx_complete <= '1';
            end if; -- fetch_symbol and active_tx
          else
            if active_tx = '1' then
              frame_tx_complete <= '0';
            end if;
          end if; -- frame_tx_complete
        end if; -- rst
      end if; -- clk
    end process;
          

end rtl;
