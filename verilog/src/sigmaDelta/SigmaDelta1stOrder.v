


module SigmaDelta1stOrder #(
    parameter IS_LIMITED = 0,   ///< 1 if input is limited in range
    parameter IN_WIDTH   = 16,  ///< Width of input
    parameter OUT_WIDTH  = 1    ///< Width of sigma-delta compressed output
) 
(
    input clk,
    input rst,
    input en,
    input signed [IN_WIDTH-1:0] in,
    output signed [OUT_WIDTH-1:0] sdOut
);

localparam LIMIT = (IS_LIMITED && (OUT_WIDTH != 1)) ? 1 : 0;

localparam ACC_MSB = LIMIT ? (IN_WIDTH-OUT_WIDTH-1) : (IN_WIDTH-OUT_WIDTH);

reg [ACC_MSB:0] acc;
reg signed [OUT_WIDTH-1:0] sd;

initial begin
    acc = 'd0;
    sd = 'd0;
end

assign unsignedIn = {in[IN_WIDTH-1], in[IN_WIDTH-2:0]};

always @(posedge clk) begin
    if (rst) begin
        acc <= 1 << (ACC_MSB);
        sd  <= 'd0;
    end else if (en) begin
        if (LIMIT) begin
            {sd, acc} <= $signed({1'b0, acc}) + in;
        end
        else if (OUT_WIDTH > 1) begin
            {sd, acc} <= $signed({1'b0, ~acc[ACC_MSB], acc[ACC_MSB-1:0]}) + in;
        end
        else begin
            {sd, acc} <= $signed({~acc[ACC_MSB], acc[ACC_MSB-1:0]}) + in;
        end
    end
end

assign sdOut = sd;

endmodule
