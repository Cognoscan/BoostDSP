--! @file lfsr_internal_ea.vhd
--! @brief library entity containing 


--! Standard Library
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! BoostDSP Library
library BoostDSP;
use BoostDSP.util_pkg.all;
use BoostDSP.lfsr_pkg.all;

--!
entity lfsr_internal is
  generic (
    INTERNAL_SIZE : positive := 8;    -- Set internal size of LFSR
    SEED          : natural := 1;     -- Choose custom seed of LFSR
    USE_XNOR      : boolean := true;  -- Use XNOR instead of XOR for feedback
    USE_CUSTOM_POLY : boolean := false; -- Use custom polynomial
    CUSTOM_POLY   : std_logic_vector := (1 downto 0 => '0')); -- Custom polynomial
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    q   : out std_logic_vector);
end entity;

-- Many-to-one Architecture of LFSR
architecture direct of lfsr_internal is

  -- Find necessary size of internal register
  constant WIDTH      : positive := max(max(2, INTERNAL_SIZE), q'length);
  -- Make a subtype to define the range of the internal register
  subtype int_range is natural range (WIDTH - 1) downto 0;
  -- Make a subtype for the internal register. Used in polynomial function too
  subtype int_reg_type is std_logic_vector(int_range);

  -- LFSR full internal register
  signal lfsr_reg : int_reg_type := std_logic_vector(to_unsigned(SEED, WIDTH));
  -- Polynomial constant to generate feedback
  constant poly   : int_reg_type := Maximal_Polynomial(WIDTH);
  -- Reversed polynomial constant used in direct feedback
  constant reverse_poly : int_reg_type := reverse(poly);
  
  -- Reference to a bad seed of all '1'. Will cause lock-up state.
  constant BAD_SEED : int_reg_type := (others => '1');

begin

  -- Warn if chosen seed will cause lock-up
  assert std_logic_vector(to_unsigned(SEED, WIDTH)) /= BAD_SEED 
    report "Chosen seed will cause LFSR lock-up" 
    severity warning;
  
  -- Generate LFSR pipeline
  data_pipeline : process(clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        lfsr_reg <= std_logic_vector(to_unsigned(SEED, WIDTH));
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

end direct;


architecture galois of lfsr_internal is

  -- Find necessary size of internal register
  constant width      : positive := max(max(2, INTERNAL_SIZE), q'length);
  -- Make a subtype to define the range of the internal register
  subtype int_range is natural range (width - 1) downto 0;
  -- Make a subtype for the internal register. Used in polynomial function too
  subtype int_reg is std_logic_vector(int_range);

  -- LFSR full internal register
  signal lfsr_reg : int_reg := std_logic_vector(to_unsigned(SEED, width));

   -- Polynomial constant to generate feedback
  constant poly   : int_reg_type := Maximal_Polynomial(WIDTH);
  
  -- Reference to a bad seed of all '1'. Will cause lock-up state.
  constant BAD_SEED : int_reg := (others => '1');

begin

  -- Warn if chosen seed will cause lock-up
  assert std_logic_vector(to_unsigned(SEED, width)) /= BAD_SEED 
    report "Chosen seed will cause LFSR lock-up" 
    severity warning;
  
  -- Generate LFSR pipeline
  data_pipeline : process(clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        lfsr_reg <= std_logic_vector(to_unsigned(SEED, width));
      else
        -- Galois LFSR
        for i in lfsr_reg'range loop
          if i = lfsr_reg'high then
            lfsr_reg(i) <= lfsr_reg(0);
          else
            if poly(i) = '1' then
              -- With XNOR, if register fails to initialize to SEED, it will
              -- still not lock-up with a zeroed-out register.
              -- Refer to Xilinx App Note XAPP 052 for full explanation.
              lfsr_reg(i) <= lfsr_reg(i+1) xnor lfsr_reg(0);
            else
              lfsr_reg(i) <= lfsr_reg(i+1);
            end if;
          end if;
        end loop;
      end if; -- rst = '1'
    end if; -- rising_edge(clk)
  end process;

  q <= lfsr_reg(q'range);

end galois;


