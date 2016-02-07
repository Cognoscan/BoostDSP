/*
* Quarter-wave Cosine & Sine table. 
* Features:
* - Parameterized for arbitrary input & output widths
* - 1/2 LSB angle offset for glitch-free quarter wave trig table
* - Unsigned quarter wave Lookup table
* - Table size is 2^(ANGLE_WIDTH-2) x OUT_WIDTH-1
* - 2 clock delay between input and output
*
* For a size example, an 18-bit output with a 12-bit angle requires a 1024x17 
* table, which readily fits into a single RAM16 block in a Spartan 6 FPGA.
*/

module trigTable #(
    parameter ANGLE_WIDTH = 12,
    parameter OUT_WIDTH   = 18
) (
    input  wire clk,                        ///< System Clock
    input  wire [ANGLE_WIDTH-1:0] angle,    ///< Angle to take sine of
    output reg signed [OUT_WIDTH-1:0] cos,  ///< Cosine of angle
    output reg signed [OUT_WIDTH-1:0] sin   ///< Sine of angle
);

///////////////////////////////////////////////////////////////////////////
// PARAMETER AND SIGNAL DECLARATIONS
///////////////////////////////////////////////////////////////////////////

localparam TABLE_LEN = 2**(ANGLE_WIDTH-2);

wire [ANGLE_WIDTH-3:0] sinQuarterAngle;
wire [ANGLE_WIDTH-3:0] cosQuarterAngle;

reg [OUT_WIDTH-2:0] sineTable [TABLE_LEN-1:0];
reg sinBit;
reg cosBit;
reg [OUT_WIDTH-2:0] halfSin;
reg [OUT_WIDTH-2:0] halfCos;

integer i;

///////////////////////////////////////////////////////////////////////////
// MAIN CODE
///////////////////////////////////////////////////////////////////////////

assign sinQuarterAngle =  (angle[ANGLE_WIDTH-2]) ? ~angle[ANGLE_WIDTH-3:0] : angle[ANGLE_WIDTH-3:0];
assign cosQuarterAngle = (~angle[ANGLE_WIDTH-2]) ? ~angle[ANGLE_WIDTH-3:0] : angle[ANGLE_WIDTH-3:0];

initial begin
    sinBit  = 1'b0;
    cosBit  = 1'b0;
    halfSin = 'd0;
    halfCos = 'd0;
    sin     = 'd0;
    cos     = 'd0;
    for(i=0; i<TABLE_LEN; i=i+1) begin
        sineTable[i] = $rtoi($floor($sin((i+0.5)*3.14159/(TABLE_LEN*2))*(2**(OUT_WIDTH-1)-1)+0.5));
    end
end

always @(posedge clk) begin
    sinBit   <= angle[ANGLE_WIDTH-1]; 
    cosBit   <= angle[ANGLE_WIDTH-1] ^ angle[ANGLE_WIDTH-2];
    halfSin  <= sineTable[sinQuarterAngle];
    halfCos  <= sineTable[cosQuarterAngle];
    sin      <= sinBit ? -$signed({1'b0,halfSin}) : $signed({1'b0, halfSin});
    cos      <= cosBit ? -$signed({1'b0,halfCos}) : $signed({1'b0, halfCos});
end

endmodule
