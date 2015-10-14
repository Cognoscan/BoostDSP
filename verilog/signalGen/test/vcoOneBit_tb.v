module vcoOneBit_tb ();

reg clk;
reg rst;
reg [15:0] freq;
wire outQ;
wire outD;

initial begin
    clk = 1'b0;
    rst = 1'b0;
    freq = 16'h7FFF;
    #100000 freq = 16'h2000;
    #100000 freq = 16'h4000;
    #100000 freq = 16'h8000;
    #100000 freq = 16'hFFFF;
end

always #1 clk = ~clk;

vcoOneBit uut (
    .clk(clk),         ///< System clock
    .rst(rst),         ///< Reset, active high
    .freq(freq),  ///< [15:0] Frequency of VCO
    .outQ(outQ),       ///< Rising edge output
    .outD(outD)        ///< Falling edge output
);

endmodule
