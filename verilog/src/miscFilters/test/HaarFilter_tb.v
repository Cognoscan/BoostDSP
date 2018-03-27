module HaarFilter_tb ();

parameter STAGES         = 8;
parameter INTERNAL_WIDTH = 18;
parameter IN_WIDTH       = 16;
parameter OUT_WIDTH      = 16;

reg clk;                                    ///< System clock
reg rst;                                    ///< Reset, synchronous and active high
reg en;                                     ///< Enable (once per new sample)
reg signed [IN_WIDTH-1:0] dataIn;           ///< Input samples
wire [STAGES:0] outStrobes;             ///< Strobes for each output
wire [OUT_WIDTH*(STAGES+1)-1:0] dataOut; ///< Outputs from analysis filter

integer i;
integer j;
reg [OUT_WIDTH-1:0] results [STAGES:0];

always #1 clk = ~clk;

initial begin
    clk = 1'b0;
    rst = 1'b0;
    en = 1'b0;
    dataIn = 'd0;
    @(posedge clk) rst = 1'b1;
    @(posedge clk) rst = 1'b1;
    @(posedge clk) rst = 1'b0;
    @(posedge clk) rst = 1'b0;
    @(posedge clk) en = 1'b0;
    @(posedge clk) en = 1'b1; dataIn = 'd0;
    @(posedge clk) en = 1'b0;
    for (i=0; i<2**8; i=i+2) begin
        @(posedge clk) en = 1'b1; dataIn = i;
        @(posedge clk) en = 1'b0;
    end
    for (i=0; i<2**8; i=i+2) begin
        @(posedge clk) en = 1'b1; dataIn = 2**8-i;
        @(posedge clk) en = 1'b0;
    end
    for (i=0; i<2**8; i=i+2) begin
        @(posedge clk) en = 1'b1; dataIn = -i;
        @(posedge clk) en = 1'b0;
    end
    for (i=0; i<2**8; i=i+2) begin
        @(posedge clk) en = 1'b1; dataIn = -(2**8)+i;
        @(posedge clk) en = 1'b0;
    end

    for (i=0; i<2**20; i=i+1) begin
        @(posedge clk) en = 1'b1; dataIn = $rtoi((2.0**(IN_WIDTH-1)-1)*$sin(3.141259*2.0*($itor(i)/2.0**15 + $itor(i)**2/2.0**23)));
        @(posedge clk) en = 1'b0;
    end
    #1000 $stop;
end

always @(dataOut) begin
    for (j=0; j<=STAGES; j=j+1) begin
        results[j] = dataOut[(OUT_WIDTH*j)+:OUT_WIDTH];
    end
end

HaarFilter #(
    .STAGES(STAGES),
    .INTERNAL_WIDTH(INTERNAL_WIDTH),
    .IN_WIDTH(IN_WIDTH),
    .OUT_WIDTH(OUT_WIDTH)
)
uut (
    .clk(clk),               ///< System clock
    .rst(rst),               ///< Reset, synchronous and active high
    .en(en),                 ///< Enable (once per new sample)
    .dataIn(dataIn),         ///< [IN_WIDTH-1:0] Input samples
    .outStrobes(outStrobes), ///< [STAGES:0] Strobes for each output
    .dataOut(dataOut)        ///< [OUT_WIDTH*(STAGES+1)-1:0] Outputs from analysis filter
);

endmodule
