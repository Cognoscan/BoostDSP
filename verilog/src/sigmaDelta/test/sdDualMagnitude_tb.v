module sdDualMagnitude_tb ();

parameter WIDTH = 16;
parameter GAIN = 8;

// UUT Signals
reg clk;              ///< System Clock
reg rst;              ///< Reset, active high & synchronous
reg en;               ///< Enable (use to clock at slower rate)
wire in;              ///< Sigma-delta input
wire [WIDTH-1:0] out; ///< Magnitude of signal

// Testbench Signals
reg signed [15:0] signalSin;
reg signed [15:0] signalCos;
integer i;

always #1 clk = ~clk;

initial begin
    clk       = 1'b0;
    rst       = 1'b1;
    en        = 1'b1;
    signalSin = 'd0;
    signalCos = 'd32767;
    @(posedge clk) rst = 1'b1;
    @(posedge clk) rst = 1'b1;
    @(posedge clk) rst = 1'b0;
    for (i=0; i<2**13; i=i+1) begin
        //#100 signalSin = $rtoi(32767.0*$sin(3.141259*2.0*($itor(i)/2.0**10 + $itor(i)**2/2.0**17)));
        //     signalCos = $rtoi(32767.0*$cos(3.141259*2.0*($itor(i)/2.0**10 + $itor(i)**2/2.0**17)));
        #100 signalSin = $rtoi((32767.0-4*i)*$sin(3.141259*2.0*($itor(i)/2.0**7)));
             signalCos = $rtoi((32767.0-4*i)*$cos(3.141259*2.0*($itor(i)/2.0**7)));
    end
    #100 $stop();
end

integer squared;
integer sqrtTrue;
integer sqrtOut;
integer ratio;
always @(posedge clk) begin
    squared = signalSin**2 + signalCos**2;
    sqrtTrue = $sqrt(squared);
    sqrtOut = $sqrt(out);
    ratio = (sqrtOut != 0) ? sqrtTrue/sqrtOut : sqrtTrue;
end

SigmaDelta2ndOrder #(
    .WIDTH(16),
    .GROWTH(2)
) 
sinModulator
(
    .clk(clk),
    .rst(rst),
    .en(en),
    .in(signalSin), ///< [WIDTH-1:0] 
    .sdOut(inSin)
);

SigmaDelta2ndOrder #(
    .WIDTH(16),
    .GROWTH(2)
) 
cosModulator
(
    .clk(clk),
    .rst(rst),
    .en(en),
    .in(signalCos), ///< [WIDTH-1:0] 
    .sdOut(inCos)
);

sdDualMagnitude #(
    .WIDTH(WIDTH),
    .GAIN(GAIN)
)
uut (
    .clk(clk),     ///< System Clock
    .rst(rst),     ///< Reset, active high & synchronous
    .en(en),       ///< Enable (use to clock at slower rate)
    .inSin(inSin), ///< Sigma-delta input
    .inCos(inCos), ///< Sigma-delta input
    .out(out)      ///< [WIDTH-1:0] Magnitude of signal
);

SmallLpf #(
    .WIDTH(16),
    .FILT_BITS(10)
)
ratioFilt (
    .clk(clk),
    .rst(rst),
    .en(1'b1),
    .dataIn(ratio[15:0]),
    .dataOut()
);

endmodule
