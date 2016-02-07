/*
Function Generator
==================

Simple function generator for debugging use. Provides 4 waveform types, with an 
adjustable frequency, amplitude, and offset. Dithering is utilized to ensure 
true reproduction of the waveform at low amplitudes, akin to acting as 
a 2*OUT_WIDTH to OUT_WIDTH bit compressor / sigma-delta modulator.

Possible Waveforms (select with waveType):
0 - Sine
1 - Triangle
2 - Square
3 - Sawtooth

Note:
For the sake of keeping BRAM usage low, the internal sine table is limited to 
a 10bx18b quarter-wave look-up table. If this needs to be adjusted, modify the 
ANGLE_WIDTH and SINE_WIDTH local parameters. You will likely not need to do this.

*/


module functionGen #(
    parameter OUT_WIDTH = 16,      ///< Output word width
    parameter FREQ_WIDTH = 16,     ///< Input frequency word width
    parameter INCLUDE_CLAMP = 1'b1 ///< Clamp the output to prevent wraparound
)
(
    // Inputs
    input clk,                       ///< System clock
    input rst,                       ///< Synchronous reset, active high
    input en,                        ///< Output next sample when high
    input [1:0] waveType,            ///< Waveform type (see top description)
    input [FREQ_WIDTH-1:0] freq,     ///< Frequency
    input [OUT_WIDTH-1:0] offset,    ///< Offset value
    input [OUT_WIDTH-1:0] amplitude, ///< Amplitude of waveform
    // Outputs
    output signed [OUT_WIDTH-1:0] outSignal
);

///////////////////////////////////////////////////////////////////////////
// PARAMETER DECLARATIONS
///////////////////////////////////////////////////////////////////////////

localparam WAVE_SINE     = 0;
localparam WAVE_TRIANGLE = 1;
localparam WAVE_SQUARE   = 2;
localparam WAVE_SAWTOOTH = 3;

localparam ANGLE_WIDTH = 10;
localparam SINE_WIDTH = 18;
localparam TABLE_LEN = 2**(ANGLE_WIDTH);

///////////////////////////////////////////////////////////////////////////
// SIGNAL DECLARATIONS
///////////////////////////////////////////////////////////////////////////

wire signed [OUT_WIDTH*2-1:0] wideSignalWordAdd;
wire [FREQ_WIDTH-3:0] xorPhase;
wire clamp;

reg signed [OUT_WIDTH-1:0] sineOrTriangle;
reg signed [OUT_WIDTH*2+1:0] wideSignalWord;
reg signed [OUT_WIDTH-1:0] unscaledSignal;
reg signed [OUT_WIDTH-1:0] clampedSignal;

reg [FREQ_WIDTH-1:0] phase;
reg [SINE_WIDTH-1:0] sineTable [TABLE_LEN-1:0];
reg [SINE_WIDTH-1:0] halfSine;
reg [OUT_WIDTH-2:0] halfSineOrTriangle;
reg signBit;
reg signBitD1;

integer i;

///////////////////////////////////////////////////////////////////////////
// MAIN CODE
///////////////////////////////////////////////////////////////////////////

if (INCLUDE_CLAMP) begin
    assign outSignal = clampedSignal;
end
else begin
    assign outSignal = wideSignalWord[2*OUT_WIDTH-1:OUT_WIDTH];
end
assign wideSignalWordAdd = {offset, wideSignalWord[OUT_WIDTH-1:0]};

assign clamp = ((wideSignalWord[2*OUT_WIDTH+1] != wideSignalWord[2*OUT_WIDTH]) 
             |  (wideSignalWord[2*OUT_WIDTH+1] != wideSignalWord[2*OUT_WIDTH-1]));

always @(posedge clk) begin
    if (rst) begin
        phase          <= 'd0;
        wideSignalWord <= 'd0;
        unscaledSignal <= 'd0;
    end
    else if (en) begin
        phase          <= phase + freq;
        wideSignalWord <= unscaledSignal * $signed({1'b0, amplitude}) + wideSignalWordAdd;

        clampedSignal  <= clamp
                        ? {wideSignalWord[2*OUT_WIDTH+1], {(OUT_WIDTH-1){~wideSignalWord[2*OUT_WIDTH+1]}}}
                        :  wideSignalWord[2*OUT_WIDTH-1:OUT_WIDTH];

        case (waveType)
            WAVE_SINE     : unscaledSignal <= sineOrTriangle;
            WAVE_TRIANGLE : unscaledSignal <= sineOrTriangle;
            WAVE_SQUARE   : unscaledSignal <= {phase[FREQ_WIDTH-1], {(OUT_WIDTH-2){~phase[FREQ_WIDTH-1]}}, 1'b1};
            WAVE_SAWTOOTH : begin
                if (FREQ_WIDTH >= OUT_WIDTH) begin
                    unscaledSignal <= $signed(phase) >>> (FREQ_WIDTH-OUT_WIDTH);
                end
                else begin
                    unscaledSignal <= $signed(phase) <<< (OUT_WIDTH-FREQ_WIDTH);
                end
            end
        endcase
    end
end

assign xorPhase = (phase[FREQ_WIDTH-2]) ? ~phase[FREQ_WIDTH-3:0] : phase[FREQ_WIDTH-3:0];

initial begin
    signBit            = 1'b0;
    signBitD1          = 1'b0;
    halfSine           = 'd0;
    halfSineOrTriangle = 'd0;
    sineOrTriangle     = 'd0;
    for(i=0; i<TABLE_LEN; i=i+1) begin
        sineTable[i] = $rtoi($floor($sin((i+0.5)*3.14159/(TABLE_LEN*2))*(2**SINE_WIDTH-1)+0.5));
    end
end

always @(posedge clk) begin
    if (en) begin
        signBit    <= phase[FREQ_WIDTH-1];
        signBitD1  <= signBit;
        // Get sine wave from look-up table
        if (FREQ_WIDTH-2 >= ANGLE_WIDTH) begin
            halfSine <= sineTable[xorPhase >> (FREQ_WIDTH-2-ANGLE_WIDTH)];
        end
        else begin
            halfSine <= sineTable[{xorPhase,{(ANGLE_WIDTH-FREQ_WIDTH+2){1'b0}}}];
        end
        // Generate the appropriate multiplexer
        if ((SINE_WIDTH > OUT_WIDTH-1) && (FREQ_WIDTH > OUT_WIDTH)) begin
            halfSineOrTriangle <= (waveType[0]) // 1=triangle, 0=sine
                                ? {xorPhase,1'b1} >> (FREQ_WIDTH-OUT_WIDTH) : halfSine >> (SINE_WIDTH-OUT_WIDTH+1);
        end 
        else if ((SINE_WIDTH > OUT_WIDTH-1) && (FREQ_WIDTH <= OUT_WIDTH)) begin
            halfSineOrTriangle <= (waveType[0]) // 1=triangle, 0=sine
                                ? {xorPhase,1'b1} << (OUT_WIDTH-FREQ_WIDTH) : halfSine >> (SINE_WIDTH-OUT_WIDTH+1);
        end 
        else if ((SINE_WIDTH <= OUT_WIDTH-1) && (FREQ_WIDTH > OUT_WIDTH)) begin
            halfSineOrTriangle <= (waveType[0]) // 1=triangle, 0=sine
                                ? {xorPhase,1'b1} >> (FREQ_WIDTH-OUT_WIDTH) : halfSine << (OUT_WIDTH-1-SINE_WIDTH);
        end 
        else begin
            halfSineOrTriangle <= (waveType[0]) // 1=triangle, 0=sine
                                ? {xorPhase,1'b1} << (OUT_WIDTH-FREQ_WIDTH) : halfSine << (OUT_WIDTH-1-SINE_WIDTH);
        end 
        // Get the final, signed number
        //sineOrTriangle <= signBitD1 ? -$signed({1'b0,halfSineOrTriangle}) : $signed({1'b0,halfSineOrTriangle});
        sineOrTriangle <= $signed({OUT_WIDTH{signBitD1}} ^ {1'b0, halfSineOrTriangle}) + $signed({1'b0, signBitD1});
    end
end
endmodule
