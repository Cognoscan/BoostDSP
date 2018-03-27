/*
Function Generator
==================

This is a simple function generator for debugging use. It provides 4 waveform 
types, with an adjustable frequency, phase offset, amplitude, and offset. 

Dithering / Bit Compression
---------------------------
Dithering is utilized to ensure true reproduction of the waveform at low 
amplitudes, akin to acting as an `OUT_WIDTH+18` bit to `OUT_WIDTH` bit compressor 
/ 1st-order sigma-delta modulator. This shapes truncation noise, pushing it to 
higher frequencies. If a flat truncation noise profile is desired, it can be 
worth disabling this by setting `BIT_COMPRESS_OUTPUT` to 0. Generally, if the use 
case requires frequencies above 1/32 of the sample rate, or primarily operates 
above 1/64 of the sample rate, this should be bypassed.

The phase word is also compressed when used as the phase input into the sine 
lookup table. This can be bypassed by setting `BIT_COMPRESS_PHASE` to 0.

Clamping the Output
-------------------
To prevent overflow when scaling the signal and adding the offset, the 
calculated signal is clamped before being output. The clamp can be safely left 
out if:

- offset + (amplitude/2) < 2^OUT_WIDTH-2
- offset - (amplitude/2) > -2^OUT_WIDTH + 1
- amplitude < 2^OUT_WIDTH - 2 (only if `BIT_COMPRESS_OUTPUT` set to 1)

To be clear, the amplitude MUST not be at its maximum value. Otherwise the bit 
compressor can cause overflow to occur. This is not a problem if the bit 
compressor is not used.

Waveform Selection
------------------
Possible Waveforms:

| waveType | Description |
| -------- | ----------- |
| 0        | Sine        |
| 1        | Triangle    |
| 2        | Square      |
| 3        | Sawtooth    |

Architecture Selection
----------------------

the `ARCH` parameter is meant for future optimization for various logic 
architectures. The current system is optimized for Spartan 6 and 7-Series Xilinx 
parts (`XIL_SPARTAN6` and `XIL_7SERIES`). If supporting another architecture, 
this module will need to be extended.

Notes on Internals
------------------
For the sake of keeping BRAM usage low, the internal sine table is limited to 
a 10bx18b quarter-wave look-up table. If this needs to be adjusted, modify the 
`ANGLE_WIDTH` and `SINE_WIDTH` local parameters. You will likely not need to do 
this.

For the amplitude scaling, a multiplier with an 18-bit wide internal input is 
assumed. This can be adjusted using the `LOCAL_WIDTH` parameter.

The offset & error feedback for the bit compressor are concatenated to form 
a single value to add to the scaled signal value. The resulting multiply + add 
step should fit into a single multiply-add block. For Xilinx components, this 
means it should be inferred as a DSP48 block. If it isn't, this module will need 
to be modified to use the ARCH parameter to specifically instantiate a DSP block.

*/


module functionGen #(
    parameter ARCH                = "GENERIC", ///< System architecture
    parameter BIT_COMPRESS_PHASE  = 1,         ///< 1 for bit compression, 0 for truncation
    parameter BIT_COMPRESS_OUTPUT = 1,         ///< 1 for bit compression, 0 for truncation
    parameter OUT_WIDTH           = 16,        ///< Output word width
    parameter FREQ_WIDTH          = 16,        ///< Input frequency word width
    parameter INCLUDE_CLAMP       = 1          ///< Clamp the output to prevent wraparound
)
(
    // Inputs
    input clk,                          ///< System clock
    input rst,                          ///< Synchronous reset, active high
    input en,                           ///< Output next sample when high
    input [1:0] waveType,               ///< Waveform type (see top description)
    input [FREQ_WIDTH-1:0] freq,        ///< Frequency
    input [FREQ_WIDTH-1:0] phaseOffset, ///< Phase offset
    input [OUT_WIDTH-1:0] offset,       ///< Offset value
    input [OUT_WIDTH-1:0] amplitude,    ///< Amplitude of waveform
    // Outputs
    output signed [OUT_WIDTH-1:0] outSignal
);

///////////////////////////////////////////////////////////////////////////
// PARAMETER DECLARATIONS
///////////////////////////////////////////////////////////////////////////

// Verify Parameters are correct
initial begin
    if (ARCH != "GENERIC" && ARCH != "XIL_7SERIES" && ARCH != "XIL_SPARTAN6") begin
        $display("Attribute ARCH on functionGen instance %m is set to %s. Valid values are GENERIC, XIL_7SERIES, and XIL_SPARTAN6.", ARCH);
        #1 $finish;
    end
    if (BIT_COMPRESS_PHASE != 0 && BIT_COMPRESS_PHASE != 1) begin
        $display("Attribute BIT_COMPRESS_PHASE on functionGen instance %m is set to %i. Valid values are 0 and 1.", BIT_COMPRESS_PHASE);
        #1 $finish;
    end
    if (BIT_COMPRESS_OUTPUT != 0 && BIT_COMPRESS_OUTPUT != 1) begin
        $display("Attribute BIT_COMPRESS_OUTPUT on functionGen instance %m is set to %i. Valid values are 0 and 1.", BIT_COMPRESS_OUTPUT);
        #1 $finish;
    end
    if (OUT_WIDTH < 3) begin
        $display("Attribute OUT_WIDTH on functionGen instance %m is set to %i. Must be at least 3.", OUT_WIDTH);
        #1 $finish;
    end
    if (FREQ_WIDTH < 4) begin
        $display("Attribute FREQ_WIDTH on functionGen instance %m is set to %i. Must be at least 4.", FREQ_WIDTH);
        #1 $finish;
    end
    if (INCLUDE_CLAMP != 0 && INCLUDE_CLAMP != 1) begin
        $display("Attribute INCLUDE_CLAMP on functionGen instance %m is set to %i. Valid values are 0 and 1.", INCLUDE_CLAMP);
        #1 $finish;
    end
end

// Reference parameters for wave type
localparam WAVE_SINE     = 0;
localparam WAVE_TRIANGLE = 1;
localparam WAVE_SQUARE   = 2;
localparam WAVE_SAWTOOTH = 3;

// Parameters determined by architecture
localparam LOCAL_WIDTH = 18; // Local width of the signal, before being compressed to final output
localparam ANGLE_WIDTH = 10;
localparam SINE_WIDTH = 18;

// Calculated parameters
localparam TABLE_LEN = 2**(ANGLE_WIDTH);
localparam WIDE_WIDTH = OUT_WIDTH+LOCAL_WIDTH;

///////////////////////////////////////////////////////////////////////////
// SIGNAL DECLARATIONS
///////////////////////////////////////////////////////////////////////////

wire [FREQ_WIDTH-3:0] xorPhase;
wire [ANGLE_WIDTH-1:0] xorSdPhase;

reg signed [LOCAL_WIDTH-1:0] sineOrTriangle;
reg signed [WIDE_WIDTH+1:0] wideSignalWord;
reg signed [LOCAL_WIDTH-1:0] unscaledSignal;
reg signed [OUT_WIDTH-1:0] clampedSignal;

reg [ANGLE_WIDTH+1:0] sdPhase;
reg [FREQ_WIDTH-1:0] phaseAcc;
reg [FREQ_WIDTH-1:0] phase;
reg [SINE_WIDTH-1:0] sineTable [TABLE_LEN-1:0];
reg [SINE_WIDTH-1:0] halfSine;
reg [LOCAL_WIDTH-2:0] halfSineOrTriangle;
reg signBit;
reg signBitD1;

integer i;

///////////////////////////////////////////////////////////////////////////
// MAIN CODE
///////////////////////////////////////////////////////////////////////////

always @(posedge clk) begin
    if (rst) begin
        phase          <= 'd0;
        phaseAcc       <= 'd0;
        wideSignalWord <= 'd0;
        unscaledSignal <= 'd0;
    end
    else if (en) begin
        // Phase accumulator with offset
        phaseAcc       <= phaseAcc + freq;
        phase          <= phaseAcc + phaseOffset;

        // Pick appropriate unscaled waveform
        case (waveType)
            WAVE_SINE     : unscaledSignal <= sineOrTriangle;
            WAVE_TRIANGLE : unscaledSignal <= sineOrTriangle;
            WAVE_SQUARE   : unscaledSignal <= {phase[FREQ_WIDTH-1], {(LOCAL_WIDTH-2){~phase[FREQ_WIDTH-1]}}, 1'b1};
            WAVE_SAWTOOTH : begin
                if (FREQ_WIDTH >= LOCAL_WIDTH) begin
                    unscaledSignal <= $signed(phase) >>> (FREQ_WIDTH-LOCAL_WIDTH);
                end
                else begin
                    unscaledSignal <= $signed(phase) <<< (LOCAL_WIDTH-FREQ_WIDTH);
                end
            end
        endcase

        // Scale value based on amplitude word, then add offset & feedback the 
        // truncated bits (bit compressor)
        if (BIT_COMPRESS_OUTPUT) begin
            wideSignalWord <= unscaledSignal * $signed({1'b0, amplitude}) 
                            + $signed({offset, wideSignalWord[LOCAL_WIDTH-1:0]});
        end
        else begin
            // Skip bit compressor (don't feed back the truncated bits)
            wideSignalWord <= unscaledSignal * $signed({1'b0, amplitude}) 
                            + $signed({offset, {LOCAL_WIDTH{1'b0}}});
        end

        // Clamp the scaled value with offset. Not needed if user knows the offset + scaled value will never overflow
        // Clamp if top three bits don't all match
        clampedSignal  <= !(&wideSignalWord[WIDE_WIDTH+1-:3] | ~|wideSignalWord[WIDE_WIDTH+1-:3])
                        ? {wideSignalWord[WIDE_WIDTH+1], {(OUT_WIDTH-1){~wideSignalWord[WIDE_WIDTH+1]}}}
                        :  wideSignalWord[WIDE_WIDTH-1-:OUT_WIDTH];

    end
end

// Final output signal is either the clamped signal or the truncated signal
if (INCLUDE_CLAMP) begin
    assign outSignal = clampedSignal;
end
else begin
    assign outSignal = wideSignalWord[WIDE_WIDTH-1-:OUT_WIDTH];
end

///////////////////////////////////////////////////////////////////////////
// Phase Word Compressor
///////////////////////////////////////////////////////////////////////////

if (ANGLE_WIDTH+2 >= FREQ_WIDTH) begin
    always @(phase) begin
        sdPhase = phase << (ANGLE_WIDTH+2-FREQ_WIDTH);
    end
end
else if (BIT_COMPRESS_PHASE) begin
    reg [(FREQ_WIDTH-ANGLE_WIDTH-3):0] sdPhaseAcc;
    always @(posedge clk) begin
        if (rst) begin
            sdPhase <= 'd0;
            sdPhaseAcc <= 'd0;
        end
        else begin
            {sdPhase,sdPhaseAcc} <= phase + sdPhaseAcc;
        end
    end
end
else begin
    always @(phase) begin
        sdPhase = phase >> (FREQ_WIDTH-ANGLE_WIDTH-2);
    end
end


///////////////////////////////////////////////////////////////////////////
// Sine Lookup Table / Triangle wave generation
///////////////////////////////////////////////////////////////////////////

// XOR phase as part of quarter-wave lookup
assign xorPhase = (phase[FREQ_WIDTH-2]) ? ~phase[FREQ_WIDTH-3:0] : phase[FREQ_WIDTH-3:0];

if (BIT_COMPRESS_PHASE) begin
    assign xorSdPhase = (sdPhase[ANGLE_WIDTH]) ? ~sdPhase[ANGLE_WIDTH-1:0] : sdPhase[ANGLE_WIDTH-1:0];
end
else begin
    if (ANGLE_WIDTH+2 >= FREQ_WIDTH) begin
        assign xorSdPhase = xorPhase << (ANGLE_WIDTH+2-FREQ_WIDTH);
    end
    else begin
        assign xorSdPhase = xorPhase >> (FREQ_WIDTH-ANGLE_WIDTH-2);
    end
end

// Initialize all signals and fill the quarter-wave lookup table
initial begin
    signBit            = 1'b0;
    signBitD1          = 1'b0;
    halfSine           = 'd0;
    halfSineOrTriangle = 'd0;
    sineOrTriangle     = 'd0;
    // 
    for(i=0; i<TABLE_LEN; i=i+1) begin
        // Use i+0.5 to get the 1/2 LSB angle offset needed to make the quarter-wave table symmetric
        // The 0.5 at the end is for rounding, as $rtoi does not round, but truncates
        sineTable[i] = $rtoi($floor($sin((i+0.5)*3.14159265358979/(TABLE_LEN*2))*(2**SINE_WIDTH-1)+0.5));
    end
end

// Get value from lookup table, multiplex accordingly for triangle wave, and 
// take negative depending on what quadrent we're in
always @(posedge clk) begin
    if (en) begin
        signBit    <= sdPhase[ANGLE_WIDTH+1];
        signBitD1  <= signBit;
        // Get sine wave from look-up table
        halfSine <= sineTable[xorSdPhase];
        // Generate the appropriate multiplexer
        if ((SINE_WIDTH > LOCAL_WIDTH-1) && (FREQ_WIDTH > LOCAL_WIDTH)) begin
            halfSineOrTriangle <= (waveType[0]) // 1=triangle, 0=sine
                                ? {xorPhase,1'b1} >> (FREQ_WIDTH-LOCAL_WIDTH) : halfSine >> (SINE_WIDTH-LOCAL_WIDTH+1);
        end 
        else if ((SINE_WIDTH > LOCAL_WIDTH-1) && (FREQ_WIDTH <= LOCAL_WIDTH)) begin
            halfSineOrTriangle <= (waveType[0]) // 1=triangle, 0=sine
                                ? {xorPhase,1'b1} << (LOCAL_WIDTH-FREQ_WIDTH) : halfSine >> (SINE_WIDTH-LOCAL_WIDTH+1);
        end 
        else if ((SINE_WIDTH <= LOCAL_WIDTH-1) && (FREQ_WIDTH > LOCAL_WIDTH)) begin
            halfSineOrTriangle <= (waveType[0]) // 1=triangle, 0=sine
                                ? {xorPhase,1'b1} >> (FREQ_WIDTH-LOCAL_WIDTH) : halfSine << (LOCAL_WIDTH-1-SINE_WIDTH);
        end 
        else begin
            halfSineOrTriangle <= (waveType[0]) // 1=triangle, 0=sine
                                ? {xorPhase,1'b1} << (LOCAL_WIDTH-FREQ_WIDTH) : halfSine << (LOCAL_WIDTH-1-SINE_WIDTH);
        end 
        // Get the final, signed number
        //sineOrTriangle <= signBitD1 ? -$signed({1'b0,halfSineOrTriangle}) : $signed({1'b0,halfSineOrTriangle});
        sineOrTriangle <= $signed({LOCAL_WIDTH{signBitD1}} ^ {1'b0, halfSineOrTriangle}) + $signed({1'b0, signBitD1});
    end
end
endmodule
