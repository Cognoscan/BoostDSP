/**

# Configurable PID Controller

Implements a low-logic-footprint PID control block, configurable at compile time.
only.

To save on logic, this controller only implements bit shifts for gain constants. 
These gain constants, KI, KP, and KD, are set as number of bits to shift 
**down** by. They are thus equivalent to 2^(-KI), etc.

           /--->(-)-->(+)-->[z^-1]-+->[KI]---\
           |     ^     ^           |         |
           |     |     |           |         |
           |     |     \-----------/         |
           |     \---------------------------+
           |                                 |
           |                                 V
inData ----+--------------------------[KP]--(+)----> outData
           |                                 ^
           |     /-->[z^-1]-\                |
           |     |          |                |
           |     |          V                |
           \-----+---------(+)--------[KD]---/

*/

module smallPidController #(
    parameter WIDTH = 16,       ///< Width of data path
    parameter KP = 0,           ///< Proportional gain
    parameter KI = 0,           ///< Integral gain
    parameter KD = 0,           ///< Differential gain
    parameter ENABLE_KP = 1,    ///< Enable Proportional section
    parameter ENABLE_KI = 1,    ///< Enable Integral section
    parameter ENABLE_KD = 0,    ///< Enable Differential section
    parameter ENABLE_CLAMP = 0, ///< Clamp the integrator to prevent overflow
    parameter ENABLE_BLEED = 0  ///< Provide an optional "bleed down" for the integrator
)
(
    input  wire clk,
    input  wire reset,
    input  wire [WIDTH-1:0] inData,
    output reg  [WIDTH-1:0] outData
);

always @(posedge clk) begin
    if (reset) begin
        outData <= 'd0;
    end
    else begin
        outData <= inData;
    end
end

endmodule
