/*
Attempts to create a 1-bit signal with a set fundamental frequency. This is done 
using a polyphase counter with the MSB used as the output.
*/

module vcoOneBit #(
    parameter WIDTH = 16    ///< Width of freq word
)
(
    input clk,              ///< System clock
    input rst,              ///< Reset, active high
    input [WIDTH-1:0] freq, ///< Frequency of VCO
    output outQ,            ///< Rising edge output
    output outD             ///< Falling edge output
);

reg [WIDTH-1:0] countQ;
reg [WIDTH-1:0] countD;

initial begin
    countQ = 'd0;
    countD = 'd0;
end

always @(posedge clk) begin
    if (rst) begin
        countQ <= 'd0;
        countD <= 'd0;
    end
    else begin
        countQ <= countD +  freq;
        countD <= countD + (freq << 1);
    end
end

assign outQ = countQ[WIDTH-1];
assign outD = countD[WIDTH-1];

endmodule
