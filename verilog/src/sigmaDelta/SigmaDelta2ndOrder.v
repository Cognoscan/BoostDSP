//
//
// Accumulators are given 2 bits of growth. If fast edge transitions are expected to occur (which, for 
// oversampling Sigma-Deltas, is generally a bad thing), this will need to be increased.
//
// 3 dB bandwidth for 64 oversampling is about Fclk / 202, it seems.

module SigmaDelta2ndOrder #(
    parameter WIDTH  = 16,      ///< Input width
    parameter GAIN   = 7.0/6.0, ///< Gain parameter
    parameter GROWTH = 2,       ///< Growth bits on accumulators
    parameter CLAMP  = 0        ///< Clamp accumulators
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
localparam integer GAIN1 = 2.0**(WIDTH-1);
localparam integer GAIN2 = 2.0**(WIDTH-1)*GAIN;
localparam ACC1_WIDTH = WIDTH+GROWTH;
localparam ACC2_WIDTH = WIDTH+2*GROWTH;

reg signed [ACC1_WIDTH-1:0] acc1;
reg signed [ACC2_WIDTH-1:0] acc2;

wire signed [ACC1_WIDTH:0] acc1Calc;
wire signed [ACC2_WIDTH:0] acc2Calc;

assign acc1Calc = acc1 + in       + $signed(acc2[ACC2_WIDTH-1] ? GAIN1 : -GAIN1);
assign acc2Calc = acc2 + acc1Calc + $signed(acc2[ACC2_WIDTH-1] ? GAIN2 : -GAIN2);

initial begin
    acc1 = 'd0;
    acc2 = 'd0;
end

always @(posedge clk) begin
    if (rst) begin
        acc1 <= 'd0;
        acc2 <= 'd0;
    end else if (en) begin
        if (CLAMP) begin
            acc1 <= (^acc1Calc[ACC1_WIDTH-:2]) ? {acc1Calc[ACC1_WIDTH], {(ACC1_WIDTH-1){acc1Calc[ACC1_WIDTH-1]}}}
                                               : acc1Calc;
            acc2 <= (^acc2Calc[ACC2_WIDTH-:2]) ? {acc2Calc[ACC2_WIDTH], {(ACC2_WIDTH-1){acc2Calc[ACC2_WIDTH-1]}}}
                                               : acc2Calc;
        end
        else begin
            acc1 <= acc1Calc;
            acc2 <= acc2Calc;
        end
    end
end

// Use the sign bit as the output
assign sdOut = ~acc2[WIDTH+2*GROWTH-1];

endmodule
