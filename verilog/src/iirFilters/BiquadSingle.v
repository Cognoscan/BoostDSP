/*

Single BiQuad IIR Filter. Uses a single DSP block and 

Scaling factor = 17-clog2(max(abs(COEFF)))
Multiply COEFFs by 2^SCALING
*/


module BiquadSingle #(
    parameter WIDTH_D = 18, // Data path width
    parameter WIDTH_C = 18, // Coeffecient bit width
    parameter COEFF_B0 = 0, // Coeffecient B0
    parameter COEFF_B1 = 0, // Coeffecient B1
    parameter COEFF_B2 = 0, // Coeffecient B2
    parameter COEFF_A1 = 0, // Coeffecient A1
    parameter COEFF_A2 = 0  // Coeffecient A2
)
(
    input  clk,                         // System clock
    input  rst,                         // Reset, active high & synchronous
    input  inStrobe,                    // Strobe on new dataIn
    input  signed [WIDTH_D-1:0] dataIn, // Input to filter
    output reg outStrobe,               // Strobes on new dataOut
    output signed [WIDTH_D-1:0] dataOut // Output from filter
);

function real AbsMax;
    input real a, b;
    begin
        a = (a < 0) ? -a : a;
        b = (b < 0) ? -b : b;
        AbsMax = (a > b) ?  a : b;
    end
endfunction

// Xilinx ISE doesn't like using system calls for localparam, so we use 
// parameter here.
parameter SCALING = -1 + $clog2($rtoi(2**(WIDTH_D-1)/
    AbsMax(AbsMax(AbsMax(AbsMax(COEFF_B0, 
                                COEFF_B1),
                                COEFF_B2),
                                COEFF_A1),
                                COEFF_A2)));

localparam ST_IDLE = 0;
localparam ST_X_B0 = 1;
localparam ST_X_B1 = 2;
localparam ST_X_B2 = 3;
localparam ST_Y_A1 = 4;
localparam ST_Y_A2 = 5;


// Calculation Engine Registers
reg signed [WIDTH_D-1:0] multInA;
reg signed [WIDTH_C-1:0] multInB;
reg signed [WIDTH_D+WIDTH_C-1:0] multOut;
reg signed [WIDTH_D+WIDTH_C+2:0] adderOut; // Allocate for multiply + 3 bits adder growth
reg signed [WIDTH_D-1:0] y;
reg signed [WIDTH_D-1:0] yD1;
reg signed [WIDTH_D-1:0] x;
reg signed [WIDTH_D-1:0] xD1;
reg signed [WIDTH_D-1:0] xD2;

// State Machine Registers
reg [2:0] state;
reg [2:0] stateD1;
reg [2:0] stateD2;
reg storeY;

// Zero out everything for initialization
initial begin
    y       = 'd0;
    yD1     = 'd0;
    x       = 'd0;
    xD1     = 'd0;
    xD2     = 'd0;
    multInA = 'd0;
    multInB = 'd0;
    multOut = 'd0;
    adderOut = 'd0;
    state   = ST_IDLE;
    stateD1 = ST_IDLE;
    stateD2 = ST_IDLE;
    storeY  = 1'b0;
    outStrobe = 1'b0;
end



assign dataOut = y;

// Calculation Engine - Should infer to DSP48 in Xilinx
always @(posedge clk) begin
    if (rst) begin
        y         <= 'd0;
        yD1       <= 'd0;
        x         <= 'd0;
        xD1       <= 'd0;
        xD2       <= 'd0;
        multInA   <= 'd0;
        multInB   <= 'd0;
        multOut   <= 'd0;
        adderOut  <= 'd0;
        outStrobe <= 1'b0;
    end
    else begin
        // Register X & delayed X on enable strobe
        if (inStrobe) begin
            x   <= dataIn;
            xD1 <= x;
            xD2 <= xD1;
        end
        // Register Y & delayed Y on output strobe
        if (storeY) begin
            y <= adderOut[SCALING+:WIDTH_D];
            yD1 <= y;
        end
        outStrobe <= storeY;
        // Determine inputs into multiplier (DSP48)
        case (state)
            ST_IDLE : begin
                multInA <= x;
                multInB <= $rtoi(COEFF_B0 * 2**SCALING);
            end
            ST_X_B0 : begin
                multInA <= x;
                multInB <= $rtoi(COEFF_B0 * 2**SCALING);
            end
            ST_X_B1 : begin
                multInA <= xD1;
                multInB <= $rtoi(COEFF_B1 * 2**SCALING);
            end
            ST_X_B2 : begin 
                multInA <= xD2;
                multInB <= $rtoi(COEFF_B2 * 2**SCALING);
            end
            ST_Y_A1 : begin 
                multInA <= y;
                multInB <= $rtoi(-COEFF_A1 * 2**SCALING);
            end
            ST_Y_A2 : begin 
                multInA <= yD1;
                multInB <= $rtoi(-COEFF_A2 * 2**SCALING);
            end
        endcase
        // Determine Adder Function (DSP48)
        case (stateD2)
            ST_IDLE : begin
                adderOut <= multOut;
            end
            ST_X_B0 : begin
                adderOut <= multOut;
            end
            ST_X_B1 : begin
                adderOut <= multOut + adderOut;
            end
            ST_X_B2 : begin 
                adderOut <= multOut + adderOut;
            end
            ST_Y_A1 : begin 
                adderOut <= multOut + adderOut;
            end
            ST_Y_A2 : begin 
                adderOut <= multOut + adderOut;
            end
        endcase
        multOut <= multInA * multInB;
    end
end

// State Machine to drive inputs to calculation engine
always @(posedge clk) begin
    if (rst) begin
        state   <= ST_IDLE;
        stateD1 <= ST_IDLE;
        stateD2 <= ST_IDLE;
    end
    else begin
        stateD1 <= state;
        stateD2 <= stateD1;
        storeY  <= (stateD2 == ST_Y_A2);
        case (state)
            ST_IDLE : state <= (inStrobe) ? ST_X_B0 : ST_IDLE;
            ST_X_B0 : state <= ST_X_B1;
            ST_X_B1 : state <= ST_X_B2;
            ST_X_B2 : state <= ST_Y_A1;
            ST_Y_A1 : state <= ST_Y_A2;
            ST_Y_A2 : state <= (inStrobe) ? ST_X_B0 : ST_IDLE;
            default : state <= ST_IDLE;
        endcase
    end
end

endmodule
