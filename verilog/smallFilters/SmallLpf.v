/*
Title: SmallLpf

Small Single-Pole IIR low-pass filter, made using just adders and bit shifts. 
Set the filter frequency using the FILT_BITS parameter.

By using power of two feedback terms, this filter is always stable and is immune 
to limit cycling.

Filter Numerator Polynomial = 1/2^(FILT_BITS)
Filter Denomenator Polynomial = 1 - z^-1 * (1-1/2^FILT_BITS)

*/

module SmallLpf #(
    parameter WIDTH = 8,
    parameter FILT_BITS = 8
)
(
    input  clk,                       // System clock
    input  rst,                       // Reset, active high and synchronous
    input  en,                        // Filter enable
    input  signed [WIDTH-1:0] dataIn, // Filter input
    output signed [WIDTH-1:0] dataOut // Filter output
);

reg signed [WIDTH+FILT_BITS-1:0] filter;

assign dataOut = filter[WIDTH+FILT_BITS-1:FILT_BITS];

always @(posedge clk) begin
    if (rst) begin
        filter <= 'd0;
    end
    else if (en) begin
        filter <= filter + dataIn - dataOut;
    end
end

endmodule

