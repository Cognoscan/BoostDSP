module sdDualMagnitude #(
    parameter WIDTH = 16,
    parameter GAIN = 6
)
(
    input clk,   ///< System Clock
    input rst,   ///< Reset, active high & synchronous
    input en,    ///< Enable (use to clock at slower rate)
    input inSin, ///< Sigma-delta input, sine channel
    input inCos, ///< Sigma-delta input, cosine channel
    output wire [WIDTH-1:0] out ///< Magnitude of signal
);

localparam WIDTH_WORD = 16;

reg [WIDTH+GAIN-1:0] acc;
reg [2:0] sinC;
reg [2:0] cosC;
reg [3:0] sums;
reg inCosD1;
reg inSinD1;


always @(posedge clk) begin
    if (rst) begin
        acc     <= 'd0;
        inCosD1 <= 1'b0;
        inSinD1 <= 1'b0;
        sinC    <= 3'b000;
        cosC    <= 3'b000;
        sums    <= 4'd0;
    end
    else if (en) begin
        inSinD1 <= inSin;
        inCosD1 <= inCos;
        sums <= {4{sinC[2]&cosC[2]}} | {1'b0, sinC[2]^cosC[2], sinC[1]&cosC[1], sinC[1]^cosC[1]};
        sinC <= (inSin ^ inSinD1) ? 3'b001 : {|sinC[2:1], sinC[0], 1'b0};
        cosC <= (inCos ^ inCosD1) ? 3'b001 : {|cosC[2:1], cosC[0], 1'b0};
        acc <= acc - (acc >>> GAIN) + {sums[2], {10{sums[3]}}, sums[1], sums[0], {3{sums[3]}}};
    end
end

assign out = (acc >>> GAIN);

endmodule
