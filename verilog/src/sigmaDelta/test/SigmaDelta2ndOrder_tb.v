module SigmaDelta2ndOrder_tb ();

parameter WIDTH  = 16;      ///< Input width
parameter GAIN   = 7.0/6.0; ///< Gain parameter
parameter GROWTH = 1;       ///< Growth bits on accumulators
parameter CLAMP  = 1;       ///< Clamp accumulators

parameter FREQ_RATE = 2000000;

reg clk;
reg rst;
reg en;
reg signed [WIDTH-1:0] in;
wire sdOut;
wire signed [15:0] dataOut;

integer i;

initial begin
    clk = 1'b0;
    rst = 1'b1;
    en = 1'b1;
    in = 'd0;
    #2 rst = 1'b0;
    #20000 in = 2**(WIDTH-1)-1;
    #20000 in = -2**(WIDTH-1)+1;
    #20000 in = 'd0;
    #20000 in = 'd0;
    for (i=1; i<2**16; i=i+1) begin
        @(posedge clk) in = $rtoi($sin($itor(i)**2*3.14159/FREQ_RATE)*(2**(WIDTH-2)-1));
    end
    for (i=1; i<2**16; i=i+1) begin
        @(posedge clk) in = $random();
    end
    $stop();
end

always #1 clk = ~clk;

SigmaDelta2ndOrder #(
    .WIDTH (WIDTH ), ///< Input width
    .GAIN  (GAIN  ), ///< Gain parameter
    .GROWTH(GROWTH), ///< Growth bits on accumulators
    .CLAMP (CLAMP )  ///< Clamp accumulators
) 
uut (
    .clk(clk),
    .rst(rst),
    .en(en),
    .in(in), ///< [WIDTH-1:0] 
    .sdOut(sdOut)
);

Sinc3Filter #(
    .OSR(32) // Output width is 3*ceil(log2(OSR))+1
)
testFilter (
    .clk(clk),
    .en(en),      ///< Enable (use to clock at slower rate)
    .in(sdOut),
    .out(dataOut) ///< [3*$clog2(OSR):0]
);



endmodule
