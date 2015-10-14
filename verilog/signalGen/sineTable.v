/*
* Quarter-wave sine table. 
* Features:
* - Parameterized for arbitrary input & output widths
* - 1/2 LSB angle offset for glitch-free quarter wave sine table
* - Unsigned quarter wave Lookup table
* - Sine table size is 2^(ANGLE_WIDTH-2) x OUT_WIDTH-1
* - 2 clock delay between input and output
*
* For a size example, an 18-bit output with a 12-bit angle requires a 1024x17 
* sine table, which readily fits into a single RAM16 block in a Spartan 6 FPGA.
*/

///////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION
///////////////////////////////////////////////////////////////////////////

module sineTable #(
    parameter ANGLE_WIDTH = 12,
    parameter OUT_WIDTH   = 18
) (
    input  wire clk,                        ///< System Clock
    input  wire [ANGLE_WIDTH-1:0] angle,    ///< Angle to take sine of
    output reg signed [OUT_WIDTH-1:0] sine ///< Sine of angle
);

///////////////////////////////////////////////////////////////////////////
// PARAMETER AND SIGNAL DECLARATIONS
///////////////////////////////////////////////////////////////////////////

localparam TABLE_LEN = 2**(ANGLE_WIDTH-2);

wire [ANGLE_WIDTH-3:0] quarterAngle;

reg [OUT_WIDTH-2:0] sineTable [TABLE_LEN-1:0];
reg signBit;
reg [OUT_WIDTH-2:0] halfSine;

integer i;

///////////////////////////////////////////////////////////////////////////
// MAIN CODE
///////////////////////////////////////////////////////////////////////////

assign quarterAngle = (angle[ANGLE_WIDTH-2]) ? ~angle[ANGLE_WIDTH-3:0] : angle[ANGLE_WIDTH-3:0];

initial begin
    signBit  = 1'b0;
    halfSine = 'd0;
    sine     = 'd0;
    for(i=0; i<TABLE_LEN; i=i+1) begin
        sineTable[i] = $rtoi($floor($sin((i+0.5)*3.14159/(TABLE_LEN*2))*(2**(OUT_WIDTH-1)-1)+0.5));
    end
end

always @(posedge clk) begin
    signBit  <= angle[ANGLE_WIDTH-1]; 
    halfSine <= sineTable[quarterAngle];
    sine     <= signBit ? -$signed({1'b0,halfSine}) : $signed({1'b0, halfSine});
end

endmodule
