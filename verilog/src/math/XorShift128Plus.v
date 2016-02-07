/**
# XorShift128Plus #

Implements the xorshift128+ algorithm. Requires a 128-bit seed value, after 
which it runs normally.

This algorithm requires 7 cycles to complete. If read is left asserted 
constantly, and data is clocked out when randomReady is high, the maximum data 
rate of this module is Clock Frequency / 7.

Note: This module is *NOT* cryptographically secure. It merely acts as a very 
fast source of pseudo-random numbers.

## Algorithm ##
```
uint64_t state0 = 1;
uint64_t state1 = 2;
uint64_t xorshift128plus() {
  uint64_t s1 = state0;
  uint64_t s0 = state1;
  state0 = s0;
  s1 ^= s1 << 23;
  s1 ^= s1 >> 17;
  s1 ^= s0;
  s1 ^= s0 >> 26;
  state1 = s1;
  return s1 + s0;
}
```

*/

module XorShift128Plus (
    input             clk,
    input             rst,
    input     [127:0] seed,
    input             seedStrobe,
    input             read,
    output reg        randomReady,
    output reg [63:0] randomValue
);

localparam ST_IDLE            = 0;
localparam ST_SEED            = 1;
localparam ST_SWAP            = 2;
localparam ST_XOR_SHIFT_23    = 3;
localparam ST_XOR_S0          = 4;
localparam ST_XOR_SHIFT_17    = 5;
localparam ST_XOR_S0_SHIFT_26 = 6;

reg [2:0] state;
reg [63:0] s0;
reg [63:0] s1;
reg [63:0] xorWord;

initial begin
    randomReady = 1'b0;
    randomValue = 64'd0;
    state       = ST_IDLE;
    s0          = 64'd1;
    s1          = 64'd2;
    xorWord     = 64'd0;
end

always @(posedge clk) begin
    if (rst) begin
    randomReady <= 1'b0;
    randomValue <= 64'd0;
    state       <= ST_IDLE;
    s0          <= 64'd1;
    s1          <= 64'd2;
    xorWord     <= 64'd0;
    end
    else begin
        // State machine (3 bit state, 3 inputs, so 6-LUT)
        case (state)
            ST_IDLE            : begin
                if (seedStrobe && randomReady) begin
                    state <= ST_SEED;
                end
                else if (read && randomReady) begin
                    state <= ST_SWAP;
                end
                else begin
                    state <= ST_IDLE;
                end
            end
            ST_SEED            : state <= ST_SWAP;
            ST_SWAP            : state <= ST_XOR_SHIFT_23;
            ST_XOR_SHIFT_23    : state <= ST_XOR_S0;
            ST_XOR_S0          : state <= ST_XOR_SHIFT_17;
            ST_XOR_SHIFT_17    : state <= ST_XOR_S0_SHIFT_26;
            ST_XOR_S0_SHIFT_26 : state <= ST_IDLE;
            default            : state <= ST_IDLE;
        endcase

        // Output is calculated on IDLE, when randomReady goes high
        if (state == ST_IDLE) begin
            randomValue <= s0 + s1;
            randomReady <= ~randomReady | (~read & ~seedStrobe); // Ready until strobe occurs; make sure it asserts at least once
        end
        else begin
            randomValue <= randomValue;
            randomReady <= 1'b0;
        end

        // s0 only updates when seeded or during the swap operation
        if (state == ST_SEED || state == ST_SWAP) begin
            s0 <= (state == ST_SWAP) ? s1 : seed[63:0];
        end

        // s1 is either swapped, XOR'd, or seeded
        case (state)
            ST_IDLE : s1 <= s1;
            ST_SEED : s1 <= seed[127:64];
            ST_SWAP : s1 <= s0;
            default : s1 <= s1 ^ xorWord;
        endcase

        // Get Word to use in the NEXT state
        case (state)
            ST_IDLE            : xorWord <= s0;
            ST_SEED            : xorWord <= s0;
            ST_SWAP            : xorWord <= s0 << 23; // s0 because the swap hasn't occured when this is calculated
            ST_XOR_SHIFT_23    : xorWord <= s0;
            ST_XOR_S0          : xorWord <= s1 >> 17;
            ST_XOR_SHIFT_17    : xorWord <= s0 >> 26;
            ST_XOR_S0_SHIFT_26 : xorWord <= s0;
            default            : xorWord <= s0;
        endcase
    end
end

endmodule
