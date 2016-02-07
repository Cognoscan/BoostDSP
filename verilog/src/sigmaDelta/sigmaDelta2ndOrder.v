//
//
// Accumulators are given 2 bits of growth. If fast edge transitions are expected to occur (which, for 
// oversampling Sigma-Deltas, is generally a bad thing), this will need to be increased.
//
// 3 dB bandwidth for 64 oversampling is about Fclk / 202, it seems.

module sigmaDelta2ndOrder #(
    parameter WIDTH = 16,
    parameter GROWTH = 2
) 
(
    input clk,
    input rst,
    input en,
    input signed [WIDTH-1:0] in,
    output sdOut
);

// For 2nd order sigma-delta modulators, signal to noise ratio (SNR) must be
// balanced against stability.  Choosing a GAIN of one would theoretically
// maximize SNR, but the feedback loop would be completely unstable. A GAIN of
// 1.16 has been found to be the best trade-off for this particular type of
// sigma-delta.  See [1]. Specifically, page 2330, gamma=2.33, scaled to 1.16 in
// our design. Be wary: I had to rearrange the order such that the scaled value
// was applied to the first integrator instead of the second, so this result may
// not 100% match the theory in the paper, and this still represents a tradeoff. 
// If you really need to squeeze out that extra 1 dB of performance, consider 
// tuning your own sigma-delta modulator, and use a higher order loop.
//
// [1] S. Hein and A. Zakhor, "On the stability of sigma delta modulators," IEEE
//     Trans Signal Proc., vol. 41, no. 7, pp. 2322-2348, July 1993. 
localparam integer GAIN = 2.0**(WIDTH-1)*1.16;

reg signed [WIDTH+GROWTH-1:0] acc1;
reg signed [WIDTH+2*GROWTH-1:0] acc2;

initial begin
    acc1 = 'd0;
    acc2 = 'd0;
end

always @(posedge clk) begin
    if (rst) begin
        acc1 <= 'd0;
        acc2 <= 'd0;
    end else if (en) begin
        acc1 <= acc1 + in + ($signed({sdOut,1'b1})*GAIN);
        acc2 <= acc2 + acc1 + in + ($signed({sdOut,1'b1}) * (GAIN + 2**WIDTH));
    end
end

// Use the sign bit as the output
assign sdOut = ~acc2[WIDTH+2*GROWTH-1];

endmodule
