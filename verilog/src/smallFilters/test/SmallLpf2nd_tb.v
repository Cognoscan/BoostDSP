module SmallLpf2nd_tb ();

parameter K0_SHIFT = 6; ///< K0 filter term = 2^-K0_SHIFT
parameter K1_SHIFT = 6; ///< K1 filter term = 2^-K1_SHIFT
parameter WIDTH = 16;   ///< Width of data path
parameter CLAMP = 1;    ///< Set to 1 to clamp the accumulators

parameter FREQ_RATE = 1000000;

reg clk;
reg rst;
reg en;
reg signed [WIDTH-1:0] dataIn;
wire signed [WIDTH-1:0] dataOut;

integer i;

initial begin
    clk = 1'b0;
    rst = 1'b1;
    en = 1'b1;
    dataIn = 'd0;
    #2 rst = 1'b0;
    for (i=1; i<2**16; i=i+1) begin
        @(posedge clk) dataIn = $rtoi($sin($itor(i)**2*3.14159/FREQ_RATE)*(2**(WIDTH-2)-1));
    end
    for (i=1; i<2**16; i=i+1) begin
        @(posedge clk) dataIn = $random();
    end
    $stop();
end

always #1 clk = ~clk;

SmallLpf2nd #(
    .K0_SHIFT(K0_SHIFT), ///< K0 filter term = 2^-K0_SHIFT
    .K1_SHIFT(K1_SHIFT), ///< K1 filter term = 2^-K1_SHIFT
    .WIDTH   (WIDTH   ), ///< Width of data path
    .CLAMP   (CLAMP   )  ///< Set to 1 to clamp the accumulators
)
uut (
    .clk(clk),        ///< System clock
    .rst(rst),        ///< Reset, active high and synchronous
    .en(en),          ///< Filter enable
    .dataIn(dataIn),  ///< [WIDTH-1:0] Filter input
    .dataOut(dataOut) ///< [WIDTH-1:0] Filter output
);

endmodule
