module SigmaDelta1stOrder #(
    parameter WIDTH = 16,
    parameter OUT_WIDTH = 1
) 
(
    input clk,
    input rst,
    input en,
    input signed [WIDTH-1:0] in,
    output signed [OUT_WIDTH-1:0] sdOut
);

wire [WIDTH-1:0] unsignedIn;
reg [WIDTH-OUT_WIDTH:0] acc;
reg signed [OUT_WIDTH-1:0] sd;

initial begin
    acc = 'd0;
    sd = 'd0;
end

assign unsignedIn = {~in[WIDTH-1], in[WIDTH-2:0]};

always @(posedge clk) begin
    if (rst) begin
        acc   <= 1 << (WIDTH-OUT_WIDTH);
        sd <= 'd0;
    end else if (en) begin
        {sd, acc} <= acc + unsignedIn;
    end
end

assign sdOut = sd;

endmodule
