/**

# Configurable PID Controller

Implements a low-logic-footprint PID control block, configurable at compile time.
only.

To save on logic, this controller only implements bit shifts for gain constants. 
These gain constants, KI, KP, and KD, are set as number of bits to shift 
**down** by. They are thus equivalent to 2^(-KI), etc.

           /--->(-)-->(+)----->[z^-1]--+->[KI]---\
           |     ^     ^               |         |
           |     |     |               |         |
           |     |     \---------------/         |
           |     \-----------[IF_BLEED]<---------+
           |                                     |
           |                                     V
inData ----+-------------------->[z^-1]-->[KP]--(+)----> outData
           |                                     ^
           |     /-->[z^-1]-\                    |
           |     |          |                    |
           |     |          V                    |
           \-----+-------->(-)-->[z^-1]-->[KD]---/

*/

module smallPidController #(
    parameter WIDTH = 16,       ///< Width of data path
    parameter KP = 0,           ///< Proportional gain
    parameter KI = 0,           ///< Integral gain
    parameter KD = 0,           ///< Differential gain
    parameter KI_WIDTH = WIDTH, ///< Width of integral path accumulator
    parameter ENABLE_KP = 1,    ///< Enable Proportional section
    parameter ENABLE_KI = 1,    ///< Enable Integral section
    parameter ENABLE_KD = 0,    ///< Enable Differential section
    parameter ENABLE_CLAMP = 0, ///< Clamp the integrator to prevent overflow
    parameter ENABLE_BLEED = 0  ///< Provide an optional "bleed down" for the integrator
)
(
    input  wire clk,
    input  wire reset,
    input  wire signed [WIDTH-1:0] inData,
    output reg  signed [WIDTH-1:0] outData
);

wire signed [KI_WIDTH:0] integratorCalc;

reg signed [WIDTH-1:0]    inDataD1;
reg signed [WIDTH:0]      differentiator;
reg signed [KI_WIDTH-1:0] integrator;

always @(posedge clk) begin
    if (reset) begin
        inDataD1       <= 'd0;
        outData        <= 'd0;
        differentiator <= 'd0;
        integrator     <= 'd0;
    end
    else begin
        // Delay input data for proportional and derivative sections
        inDataD1 <= inData;

        // Calculate output
        outData <= ((ENABLE_KP) ? (inDataD1       >>> KP) : 'd0)
                 + ((ENABLE_KI) ? (integrator     >>> KI) : 'd0) 
                 + ((ENABLE_KD) ? (differentiator >>> KD) : 'd0);

        // Differentiator
        if (ENABLE_KD) differentiator <= inData - inDataD1;
        else           differentiator <= 'd0;

        // Integrator
        if (ENABLE_KI) begin
            if (ENABLE_CLAMP) begin
                integrator <= (^integratorCalc[KI_WIDTH -: 2])
                            ? {integratorCalc[KI_WIDTH], {(KI_WIDTH-1){~integratorCalc[KI_WIDTH]}}}
                            : integratorCalc;
            end
            else begin
                integrator <= integratorCalc;
            end
        end
        else begin
            integrator <= 'd0;
        end
    end
end

endmodule
