module shiftTest ();

reg clk;
reg [7:0] counter;
reg [7:0] out;

initial begin
    clk = 1'b0;
    counter = 'd0;
    out = 'd0;
end

always #1 clk = ~clk;

always @(posedge clk) begin
    counter <= counter + 1;
    out <= counter >>> -1;
end
endmodule
