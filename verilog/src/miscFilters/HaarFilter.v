/**
HaarFilter
==========
Haar filter bank. Output is an array of signed values OUT_WIDTH bits wide, 
arranged in little-endian fashion. Word 0 is the low-pass output, word 1 is the 
corresponding high-pass output, word 2 is the high pass output from the previous 
filter pair, and so on:

```

in --+--> HPF ---------------------------> word 3
     |
     \--> LPF --+--> HPF ----------------> word 2
                |
                \--> LPF --+--> HPF -----> word 1
                           |
                           \--> LPF -----> word 0

```

The filters are multirate, downsampling after each filter pair. To save on 
resources, the filter calculation steps are interleaved. New samples are 
available on the corresponding bit in `outStrobes`.

*/

module HaarFilter #(
    parameter STAGES = 4,
    parameter INTERNAL_WIDTH = 18,
    parameter IN_WIDTH = 16,
    parameter OUT_WIDTH = 16
)
(
    input clk,                                ///< System clock
    input rst,                                ///< Reset, synchronous and active high
    input en,                                 ///< Enable (once per new sample)
    input signed [IN_WIDTH-1:0] dataIn,       ///< Input samples
    output [STAGES:0] outStrobes,             ///< Strobes for each output
    output [OUT_WIDTH*(STAGES+1)-1:0] dataOut ///< Outputs from analysis filter
);

///////////////////////////////////////////////////////////////////////////
// Parameter Declarations
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
// Signal Declarations
///////////////////////////////////////////////////////////////////////////

reg [INTERNAL_WIDTH-1:0] prevArray [STAGES-1:0];
reg [INTERNAL_WIDTH-1:0] highPass  [STAGES-1:0];
reg [INTERNAL_WIDTH-1:0] lowPass;

reg [STAGES-1:0] counter;

integer outArray;
integer i;

///////////////////////////////////////////////////////////////////////////
// Calculation Engine
///////////////////////////////////////////////////////////////////////////

always @(posedge clk) begin
    if (rst) begin
        counter <= 'd0;
    end
    else if (en) begin
        counter <= counter + 2'd1;
    end
end

///////////////////////////////////////////////////////////////////////////
// Output Mapping
///////////////////////////////////////////////////////////////////////////

// Map filter outputs onto output array
always @(*) begin
    dataOut[0+:OUT_WIDTH] = lowPass;
    for (outArray=0; outArray<STAGES; outArray = outArray+1) begin
        dataOut[(OUT_WIDTH*(outArray+1))+:OUT_WIDTH] = highPass[outArray];
    end
end

endmodule
