library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity lfsr_tb is
  generic (
    LFSR_LENGTH : positive := 8;
    DUMP_FILE   : string := string'("lfsr_dump.txt"));
end entity;

architecture sim of lfsr_tb is
  
  file dump : text open write_mode is DUMP_FILE;

  component lfsr is
    generic (
      INTERNAL_SIZE : positive;
      SEED          : natural);
    port (
      clk : in  std_logic;
      rst : in  std_logic;
      q   : out std_logic_vector);
  end component;

  constant clk_p : time := 2 ns;

  signal clk : std_logic := '0';  -- clock for uut
  signal rst : std_logic := '0';  -- reset for uut
  signal q   : std_logic_vector((LFSR_LENGTH - 1) downto 0); -- LFSR out vector
  -- Record all values output by LFSR. Set chosen(q) to '1' on each clock cycle
  signal chosen : std_logic_vector(((2 ** q'length) -2) downto 0);
  
  -- If LFSR is maximal length, then chosen will match this after
  -- 2**LFSR_LENGTH - 1 clock cycles.
  constant ALL_CHOSEN : std_logic_vector(chosen'range) := (others => '1');

begin

  -- Instantiate the LFSR to test
  uut : lfsr
    generic map (
      INTERNAL_SIZE => LFSR_LENGTH,
      SEED => 1
    ) port map (
      clk => clk,
      rst => rst,
      q   => q);

  -- Generate clock
  clk_gen : process
  begin
    clk <= not clk;
    wait for (clk_p / 2);
  end process;

  -- Generate Reset signal for 1 clock cycle
  rst_proc : process
  begin
    rst <= '1';
    wait for clk_p;
    rst <= '0';
    wait;
  end process;

  -- Record each output from LFSR into 'chosen' and file.
  record_output : process
    variable value : integer;
    variable buf : line;
  begin
    wait for clk_p;
    value := to_integer(unsigned(q));
    write(buf, value);
    writeline(dump, buf);
    chosen(value) <= '1';
  end process;

  -- Check to see if LFSR has iterated over all values.
  check_states : process
    variable buf : line;
  begin
    wait for (clk_p * (2 ** LFSR_LENGTH)); -- Give 1 extra cycle for reset.
    if chosen = ALL_CHOSEN then
      write(buf, string'("Maximal LFSR"));
    else
      write(buf, string'("Non-maximal LFSR"));
    end if;
    writeline(output, buf);
    wait;
  end process;
  
    

end sim;
