--! @file simple_tx_ea.vhd
--! @brief Instantiates a simple RF transmitter.
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

--! Standard IEEE library
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

--! All prerequisite packages in BoostDSP
use work.fixed_pkg.all;
use work.util_pkg.all;
use work.rf_blocks_pkg;
use work.basic_pkg;

--! A simple RF transmitter. It uses rf_blocks_pkg.frame_tx and basic_pkg.mapper 
--! to generate I and Q values from a buffered set of data. Setting INCLUDE_DDS 
--! to true causes these I and Q symbol values to be used to modulate the output 
--! from a DDS (rf_blocks_pkg.dds). This is mostly useful for the purposes of 
--! simulation and for systems that output directly to RF.
entity simple_tx is
  generic (
    INCLUDE_DDS : boolean := false;
    MAP_VALUES_I : real_vector;
    MAP_VALUES_Q : real_vector
  ); 
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
           freq              : in ufixed; --! Only needed if DDS is used
           i_out             : out sfixed; --! In-phase data
           q_out             : out sfixed --! Quadrature-phase data
       );
end entity;

architecture rtl of simple_tx is

  constant symbol_size : positive := integer(log2(real(map_values_i'length)));

  signal symbol_data : std_logic_vector((symbol_size - 1) downto 0);

  signal mapped_i : sfixed(i_out'range);
  signal mapped_q : sfixed(q_out'range);
  signal dds_i    : sfixed(i_out'range);
  signal dds_q    : sfixed(q_out'range);

begin
  -- State assumptions first
  assert MAP_VALUES_I'length = MAP_VALUES_Q'length
    report "Map value vectors must be of same length"
    severity error;

  select_dds : if INCLUDE_DDS = true generate

    dds_1 : rf_blocks_pkg.dds
    port map (
               clk   => clk,
               rst   => rst,
               freq  => freq,
               phase => to_ufixed(0,-1,-2),
               i_out => dds_i,
               q_out => dds_q
             );

    --! Modulation process. Multiplies DDS outputs by mapped I and Q values.
    modulate : process (clk, rst)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          i_out <= to_sfixed(0, i_out);
          q_out <= to_sfixed(0, q_out);
        else
          i_out <= resize(mapped_i * dds_i, i_out);
          q_out <= resize(mapped_q * dds_q, q_out);
        end if; -- rst
      end if; -- clk
    end process;

  end generate;

  --! If there's no DDS, modulation is unnecessary.
  no_dds : if INCLUDE_DDS = false generate
    i_out <= mapped_i;
    q_out <= mapped_q;
  end generate;

  frame_tx_1 : rf_blocks_pkg.frame_tx
    port map (
           clk               => clk,
           rst               => rst,
           frame_size        => frame_size,
           clks_per_symbol   => clks_per_symbol,
           start             => start,
           abort             => abort,
           frame_tx_complete => frame_tx_complete,
           buffer_addr       => buffer_addr,
           buffer_we         => buffer_we,
           buffer_write_data => buffer_write_data,
           buffer_read_data  => buffer_read_data,
           buffer_strobe     => buffer_strobe,
           buffer_done       => buffer_done,
           symbol_out        => symbol_data
         );

  mapper_1 : basic_pkg.mapper
    generic map (
    map_values_i => MAP_VALUES_I,
    map_values_q => MAP_VALUES_Q
  )
  port map (
         clk   => clk,
         rst   => rst,
         data  => symbol_data,
         i_out => mapped_i,
         q_out => mapped_q
       );

end rtl;
