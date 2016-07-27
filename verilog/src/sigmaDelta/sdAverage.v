/**
# Sigma-Delta Averager #

Averages two separate sigma-delta signals together and produces a single 
sigma-delta output.

*/

module sdAverage
(
    input clk,   ///< System Clock
    input rst,   ///< Reset, synchronous and active high
    input en,    ///< Enable for sigma-delta
    input in0,   ///< Sigma-delta input 0
    input in1,   ///< Sigma-delta input 1
    output sdAvg ///< Averaged result
);

reg [1:0] acc; // Accumulator for sigma-delta compressor

assign sdAvg = acc[1];
always @(posedge clk) begin
    if (rst) begin
        acc <= 2'b00;
    end
    else if (en) begin
        // Equivalent to (in0 + in1 + acc[0])
        acc[1] <= in0&in1 | in0&acc[0] | in1&acc[0];
        acc[0] <= in0 ^ in1 ^ acc[0];
    end
end

endmodule
