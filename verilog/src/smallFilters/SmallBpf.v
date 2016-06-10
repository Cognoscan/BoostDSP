/**
# SmallBpf - 2-pole IIR Bandpass Filter #

Small 2-Pole IIR band-pass filter, made using just adders and bit shifts. Set 
the frequency using the SHIFT1 and SHIFT2 parameters. It can be slowed down by 
strobing the `en` bit to run at a lower rate.

By using power of two feedback terms, this filter is alsways stable and is 
immune to limit cycling.

*/

module SmallBpf #(
    parameter WIDTH        = 16, ///< 
    parameter SHIFT_DIRECT = 10, ///< 
    parameter SHIFT_ACCUM  = 18  ///< 
)
(
    input  clk,                       ///< System clock
    input  rst,                       ///< Reset, active high and synchronous
    input  en,                        ///< Filter enable
    input  signed [WIDTH-1:0] dataIn, ///< Filter input
    output signed [WIDTH-1:0] dataOut ///< Filter output
);

reg signed [WIDTH+SHIFT_DIRECT-1:0] accumForward;
reg signed [WIDTH+SHIFT_DIRECT-SHIFT_ACCUM-1:0] accumFeedback;

always @(posedge clk) begin
    if (rst) begin
        accumForward  <= 'd0;
        accumFeedback <= 'd0;
    end
    else if (en) begin
        accumForward <= accumForward - dataIn - whatever;
        accumFeedback <= accumFeedback + huh;
    end
end


endmodule
