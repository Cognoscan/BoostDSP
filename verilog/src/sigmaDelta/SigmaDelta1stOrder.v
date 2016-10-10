module SigmaDelta1stOrder #(
    parameter WIDTH  = 16 ///< Input width
) 
(
    input clk,
    input rst,
    input en,
    input signed [WIDTH-1:0] in,
    output sdOut
);

reg signed [WIDTH:0] acc;

initial begin
    acc = 'd0;
end

always @(posedge clk) begin
    if (rst) begin
        acc <= 'd0;
    end
    else if (en) begin
        acc <= $signed({~acc[WIDTH-1], ~acc[WIDTH-1], acc[WIDTH-2:0]}) + in;
    end
end

assign sdOut = acc[WIDTH];

endmodule
