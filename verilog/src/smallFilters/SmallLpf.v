/*
# SmallLpf - Single-pole IIR Low-Pass Filter #

Small Single-Pole IIR low-pass filter, made using just adders and bit shifts. 
Set the filter frequency using the FILT_BITS parameter. It can be slowed down by 
strobing the `en` bit to run at a lower rate.

By using power of two feedback terms, this filter is always stable and is immune 
to limit cycling.

The transfer function is:

             1 / 2^N
H(z) = -------------------------------
        1 - z^-1 * (1-2^(-N))

where N = FILT_BITS. The -3 dB cutoff frequency, in radians, is:


    w = ln ( (2^N - 1) / (2^N - 2) )

The cutoff frequency in the continuous-time domain is approximately f_clk 
/ (2*pi*2^N), where f_clk is the filter's running rate. The design equation to 
select an appropriate FILT_BITS value is thus:

FILT_BITS = log2( f_clk / (2*pi*f_cutoff))

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

