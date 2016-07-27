module sdMagnitude #(
    parameter WIDTH = 16,
    parameter GAIN = 6
)
(
    input clk, ///< System Clock
    input rst, ///< Reset, active high & synchronous
    input en,  ///< Enable (use to clock at slower rate)
    input in,  ///< Sigma-delta input
    output wire [WIDTH-1:0] out ///< Magnitude of signal
);

localparam WIDTH_WORD = 16;

reg [WIDTH+GAIN-1:0] acc;
reg [WIDTH_WORD-1:0] inWord;
reg inD1;

always @(posedge clk) begin
    if (rst) begin
        acc <= 'd0;
        inWord <= 'd1;
        inD1 <= 1'b0;
    end
    else if (en) begin
        inD1 <= in;
        if (in ^ inD1) begin
            inWord <= 1;
        end
        else begin
            inWord <= {11'b0, inWord[0], 4'b0} | {16{inWord[4]}};
        end
        acc <= acc - (acc >>> GAIN) + {inWord[WIDTH_WORD-1:1], 1'b0};
    end
end

assign out = (acc >>> GAIN);

endmodule
