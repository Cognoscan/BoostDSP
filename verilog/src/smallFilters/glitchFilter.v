/*
Name: GlitchFilter

Filters out short glitches in a signal. Only features longer than FILT_LEN clks
will be passed through.
*/

module GlitchFilter #(
    parameter FILT_LEN = 1
)
(
    input  wire clk,
    input  wire inData,
    output reg  outData
);

localparam TRUE_FILT_LEN = (FILT_LEN > 0) ? FILT_LEN : 1; // Must be at least 1

reg [TRUE_FILT_LEN-1:0] delayLine;

always @(posedge clk) begin
    if (FILT_LEN < 1) begin
        outData <= inData;
    end
    if (FILT_LEN == 1) begin
        delayLine <= inData;
        outData <= outData ? (|delayLine | inData) : (&delayLine & inData);
    end
    else begin
        delayLine <= {delayLine[FILT_LEN-1:1], inData};
        outData <= outData ? (|delayLine | inData) : (&delayLine & inData);
    end
end

endmodule
