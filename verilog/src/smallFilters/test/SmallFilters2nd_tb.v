module SmallFilters2nd_tb ();

parameter K0_SHIFT = 6; ///< K0 filter term = 2^-K0_SHIFT
parameter K1_SHIFT = 6; ///< K1 filter term = 2^-K1_SHIFT
parameter WIDTH = 16;   ///< Width of data path
parameter CLAMP = 1;    ///< Set to 1 to clamp the accumulators

parameter FREQ_RATE = 4000000;

reg clk;
reg rst;
reg en;
reg signed [WIDTH-1:0] dataInCos;
reg signed [WIDTH-1:0] dataInSin;
wire signed [WIDTH-1:0] lpfSin;
wire signed [WIDTH-1:0] lpfCos;
wire signed [WIDTH-1:0] hpfSin;
wire signed [WIDTH-1:0] hpfCos;
wire signed [WIDTH-1:0] bpfSin;
wire signed [WIDTH-1:0] bpfCos;
wire signed [WIDTH-1:0] bsfSin;
wire signed [WIDTH-1:0] bsfCos;

integer i;

integer lpfMag;
integer hpfMag;
integer bpfMag;
integer bsfMag;

initial begin
    clk = 1'b0;
    rst = 1'b1;
    en = 1'b1;
    dataInCos = 'd0;
    dataInSin = 'd0;
    #2 rst = 1'b0;
    for (i=1; i<2**16; i=i+1) begin
        @(posedge clk) dataInCos = $rtoi($cos($itor(i)**2*3.14159/FREQ_RATE)*(2**(WIDTH-2)-1));
                       dataInSin = $rtoi($sin($itor(i)**2*3.14159/FREQ_RATE)*(2**(WIDTH-2)-1));
    end
    for (i=1; i<2**16; i=i+1) begin
        @(posedge clk) dataInCos = $random();
        @(posedge clk) dataInSin = $random();
    end
    $stop();
end

always #1 clk = ~clk;

always @(posedge clk) begin
    lpfMag = (((lpfSin*lpfSin + lpfCos*lpfCos)));
    hpfMag = (((hpfSin*hpfSin + hpfCos*hpfCos)));
    bpfMag = (((bpfSin*bpfSin + bpfCos*bpfCos)));
    bsfMag = (((bsfSin*bsfSin + bsfCos*bsfCos)));
end

/*****************************************************************************/
// Low Pass Filters
/*****************************************************************************/
SmallLpf2nd #(
    .K0_SHIFT(K0_SHIFT), ///< K0 filter term = 2^-K0_SHIFT
    .K1_SHIFT(K1_SHIFT), ///< K1 filter term = 2^-K1_SHIFT
    .WIDTH   (WIDTH   ), ///< Width of data path
    .CLAMP   (CLAMP   )  ///< Set to 1 to clamp the accumulators
)
uutLpfSin (
    .clk(clk),          ///< System clock
    .rst(rst),          ///< Reset, active high and synchronous
    .en(en),            ///< Filter enable
    .dataIn(dataInSin), ///< [WIDTH-1:0] Filter input
    .dataOut(lpfSin)    ///< [WIDTH-1:0] Filter output
);
SmallLpf2nd #(
    .K0_SHIFT(K0_SHIFT), ///< K0 filter term = 2^-K0_SHIFT
    .K1_SHIFT(K1_SHIFT), ///< K1 filter term = 2^-K1_SHIFT
    .WIDTH   (WIDTH   ), ///< Width of data path
    .CLAMP   (CLAMP   )  ///< Set to 1 to clamp the accumulators
)
uutLpfCos (
    .clk(clk),          ///< System clock
    .rst(rst),          ///< Reset, active high and synchronous
    .en(en),            ///< Filter enable
    .dataIn(dataInCos), ///< [WIDTH-1:0] Filter input
    .dataOut(lpfCos)    ///< [WIDTH-1:0] Filter output
);

/*****************************************************************************/
// High Pass Filters
/*****************************************************************************/
SmallHpf2nd #(
    .K0_SHIFT(K0_SHIFT), ///< K0 filter term = 2^-K0_SHIFT
    .K1_SHIFT(K1_SHIFT), ///< K1 filter term = 2^-K1_SHIFT
    .WIDTH   (WIDTH   ), ///< Width of data path
    .CLAMP   (CLAMP   )  ///< Set to 1 to clamp the accumulators
)
uutHpfSin (
    .clk(clk),          ///< System clock
    .rst(rst),          ///< Reset, active high and synchronous
    .en(en),            ///< Filter enable
    .dataIn(dataInSin), ///< [WIDTH-1:0] Filter input
    .dataOut(hpfSin)    ///< [WIDTH-1:0] Filter output
);
SmallHpf2nd #(
    .K0_SHIFT(K0_SHIFT), ///< K0 filter term = 2^-K0_SHIFT
    .K1_SHIFT(K1_SHIFT), ///< K1 filter term = 2^-K1_SHIFT
    .WIDTH   (WIDTH   ), ///< Width of data path
    .CLAMP   (CLAMP   )  ///< Set to 1 to clamp the accumulators
)
uutHpfCos (
    .clk(clk),          ///< System clock
    .rst(rst),          ///< Reset, active high and synchronous
    .en(en),            ///< Filter enable
    .dataIn(dataInCos), ///< [WIDTH-1:0] Filter input
    .dataOut(hpfCos)    ///< [WIDTH-1:0] Filter output
);

/*****************************************************************************/
// Band Pass Filters
/*****************************************************************************/
SmallBpf #(
    .K0_SHIFT(K0_SHIFT), ///< K0 filter term = 2^-K0_SHIFT
    .K1_SHIFT(K1_SHIFT), ///< K1 filter term = 2^-K1_SHIFT
    .WIDTH   (WIDTH   ), ///< Width of data path
    .CLAMP   (CLAMP   )  ///< Set to 1 to clamp the accumulators
)
uutBpfSin (
    .clk(clk),          ///< System clock
    .rst(rst),          ///< Reset, active high and synchronous
    .en(en),            ///< Filter enable
    .dataIn(dataInSin), ///< [WIDTH-1:0] Filter input
    .dataOut(bpfSin)    ///< [WIDTH-1:0] Filter output
);
SmallBpf #(
    .K0_SHIFT(K0_SHIFT), ///< K0 filter term = 2^-K0_SHIFT
    .K1_SHIFT(K1_SHIFT), ///< K1 filter term = 2^-K1_SHIFT
    .WIDTH   (WIDTH   ), ///< Width of data path
    .CLAMP   (CLAMP   )  ///< Set to 1 to clamp the accumulators
)
uutBpfCos (
    .clk(clk),          ///< System clock
    .rst(rst),          ///< Reset, active high and synchronous
    .en(en),            ///< Filter enable
    .dataIn(dataInCos), ///< [WIDTH-1:0] Filter input
    .dataOut(bpfCos)    ///< [WIDTH-1:0] Filter output
);

/*****************************************************************************/
// Band Stop Filters
/*****************************************************************************/
SmallBsf #(
    .K0_SHIFT(K0_SHIFT), ///< K0 filter term = 2^-K0_SHIFT
    .K1_SHIFT(K1_SHIFT), ///< K1 filter term = 2^-K1_SHIFT
    .WIDTH   (WIDTH   ), ///< Width of data path
    .CLAMP   (CLAMP   )  ///< Set to 1 to clamp the accumulators
)
uutBsfSin (
    .clk(clk),          ///< System clock
    .rst(rst),          ///< Reset, active high and synchronous
    .en(en),            ///< Filter enable
    .dataIn(dataInSin), ///< [WIDTH-1:0] Filter input
    .dataOut(bsfSin)    ///< [WIDTH-1:0] Filter output
);
SmallBsf #(
    .K0_SHIFT(K0_SHIFT), ///< K0 filter term = 2^-K0_SHIFT
    .K1_SHIFT(K1_SHIFT), ///< K1 filter term = 2^-K1_SHIFT
    .WIDTH   (WIDTH   ), ///< Width of data path
    .CLAMP   (CLAMP   )  ///< Set to 1 to clamp the accumulators
)
uutBsfCos (
    .clk(clk),          ///< System clock
    .rst(rst),          ///< Reset, active high and synchronous
    .en(en),            ///< Filter enable
    .dataIn(dataInCos), ///< [WIDTH-1:0] Filter input
    .dataOut(bsfCos)    ///< [WIDTH-1:0] Filter output
);

endmodule
