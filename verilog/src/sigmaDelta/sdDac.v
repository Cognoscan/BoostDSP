module sdDac #(
    parameter WIDTH = 16
) (
    input clk,
    input rst,
    input [WIDTH-1:0] in,
    output reg dac
);

reg [WIDTH-1:0] error;

always @(posedge clk) begin
    if (rst) begin
        error <= 0;
        dac <= 1'b0;
    end
    else
    begin
        {dac, error} <= error + {~in[WIDTH-1], in[WIDTH-2:0]};
    end
end

endmodule
