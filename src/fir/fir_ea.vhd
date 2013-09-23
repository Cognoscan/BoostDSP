--! @file fir_ea.vhd
--! @brief FIR filter implementations
--! @author Scott Teal (Scott@Teals.org)
--! @date 2013-09-22

--! IEEE Standard library
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! BoostDSP library 
library boostdsp;
use boostdsp.util_pkg.all;

--! @brief Entity for all types of FIR filters
--! @details
--! Any type of FIR filter implementation should be represented here.
entity fir is 
  generic (
    MACC_WIDTH : positive --! Width of the accumultor output register
    );
  port (
    clk : std_logic;  --! FIR clock
    rst : std_logic;  --! Reset line
    coeff : signed_vector;  --! Coefficient vector
    din : signed; --! FIR filter input
    dout : signed --! FIR filter output
  );
end entity fir;

architecture rtl of fir is

  constant max_out_bit : positive := din'length + coeff'length(1) - 1;
  subtype output_range is natural range max_out_bit downto max_out_bit - din'length

  --! Stores all coefficients internally
  signal coeff_internal : signed_vector(coeff'range(0))(coeff'range(1));

  --! 1st Array of stored data
  signal data_mem1 : signed_vector(coeff'range(0))(din'range);

  --! 2nd Array of stored data
  signal data_mem2 : signed_vector(coeff'range(0))(din'range);

  --! Stores all outputs from the multiply chain
  signal mult_out : signed_vector(coeff'range(0))(din'range);

  --! Stores all outputs from the MACC chain
  signal adder_out : signed_vector(coeff'range(0))(MACC_WIDTH - 1 downto 0);

begin

  data_pipeline : process (clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        coeff_internal <= (others => (others => '0'));
        data_mem1 <= (others => (others => '0'));
        data_mem2 <= (others => (others => '0'));
        mult_out <= (others => (others => '0'));
        adder_out <= (others => (others => '0'));
      else
        null;
      end if;
    end if;
  end process;

  dout <= 

end rtl;
