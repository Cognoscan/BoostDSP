module SmallLpf_tb ();

parameter WIDTH = 9;
parameter FILT_BITS = 10;

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
    #10000 dataIn = 2**(WIDTH-1)-1;
    #10000 dataIn = -2**(WIDTH-1);
    #10000
    for (i=1; i<2**16; i=i+1) begin
        @(posedge clk) dataIn = $rtoi($sin($itor(i)**2*3.14159/FREQ_RATE)*(2**(WIDTH-2)-1));
    end
    for (i=1; i<2**16; i=i+1) begin
        @(posedge clk) dataIn = $random();
    end
    $stop();
end

always #1 clk = ~clk;

SmallLpf #(
    .WIDTH(WIDTH),
    .FILT_BITS(FILT_BITS)
)
uut (
    .clk(clk),        ///< System clock
    .rst(rst),        ///< Reset, active high and synchronous
    .en(en),          ///< Filter enable
    .dataIn(dataIn),  ///< [WIDTH-1:0] Filter input
    .dataOut(dataOut) ///< [WIDTH-1:0] Filter output
);

endmodule
