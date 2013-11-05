library ieee;
use ieee.fixed_float_types.all;

package fixed_pkg is

  new ieee.fixed_generic_pkg

  generic map (

                fixed_round_style => IEEE.fixed_float_types.fixed_round,

                fixed_overflow_style => IEEE.fixed_float_types.fixed_saturate,

                fixed_guard_bits => 3, -- number of guard bits

                no_warning => false -- show warnings

              );
