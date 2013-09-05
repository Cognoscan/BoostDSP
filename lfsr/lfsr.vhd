library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lfsr is
  generic (
    IS_GALOIS     : boolean := true;  -- True for Galois, False for Direct FB
    INTERNAL_SIZE : positive := 8;    -- Set internal size of LFSR
    SEED          : natural := 1;     -- Choose custom seed of LFSR
    USE_XNOR      : boolean := true;  -- Use XNOR instead of XOR for feedback
    USE_CUSTOM_POLY : boolean := false; -- Use custom polynomial
    CUSTOM_POLY   : std_logic_vector := (1 downto 0 => '0')); -- Polynomial
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    q   : out std_logic_vector);
end entity;

architecture beh of lfsr is

  component lfsr_internal is
    generic (
      INTERNAL_SIZE   : positive;
      SEED            : natural;
      USE_XNOR        : boolean;
      USE_CUSTOM_POLY : boolean;
      CUSTOM_POLY     : std_logic_vector;
    port (
      clk : in  std_logic;
      rst : in  std_logic;
      q   : out std_logic_vector);
  end component;

begin
  
  if IS_GALOIS generate
    lfsr_direct : lfsr_internal(direct)
      generic map (
        INTERNAL_SIZE   => INTERNAL_SIZE,
        SEED            => SEED,
        USE_XNOR        => USE_XNOR,
        USE_CUSTOM_POLY => USE_CUSTOM_POLY,
        CUSTOM_POLY     => CUSTOM_POLY)
      port map (
        clk => clk,
        rst => rst,
        q   => q);
  else generate
    lfsr_galois : lfsr_internal(galois)
      generic map (
        INTERNAL_SIZE   => INTERNAL_SIZE,
        SEED            => SEED,
        USE_XNOR        => USE_XNOR,
        USE_CUSTOM_POLY => USE_CUSTOM_POLY,
        CUSTOM_POLY     => CUSTOM_POLY)
      port map (
        clk => clk,
        rst => rst,
        q   => q);
  end generate;

end beh;
