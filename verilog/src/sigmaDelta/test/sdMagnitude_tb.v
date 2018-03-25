module sdMagnitude_tb ();

parameter WIDTH = 16;
parameter GAIN = 6;

// UUT Signals
reg clk;              ///< System Clock
reg rst;              ///< Reset, active high & synchronous
reg en;               ///< Enable (use to clock at slower rate)
wire in;              ///< Sigma-delta input
wire [WIDTH-1:0] out; ///< Magnitude of signal

// Testbench Signals
reg signed [7:0] signal;
integer i;

always #1 clk = ~clk;

initial begin
    clk    = 1'b0;
    rst    = 1'b1;
    en     = 1'b1;
    signal = 'd0;
    @(posedge clk) rst = 1'b1;
    @(posedge clk) rst = 1'b1;
    @(posedge clk) rst = 1'b0;
    #10000 signal = 8'sd127;
    #10000 signal = -8'sd128;
    #10000 signal = 8'sd64;
    #10000 signal = -8'sd64;
    #10000 signal = -8'sd128;
    for (i=-128; i<127; i=i+1) begin
        #100 signal = i;
    end
    for (i=0; i<2**13; i=i+1) begin
        #100 signal = $rtoi(127.0*$sin(3.141259*2.0*($itor(i)/2.0**10 + $itor(i)**2/2.0**17)));
    end
    #10000 $stop();
end

integer squared;
always @(posedge clk) squared = signal**2;

SigmaDelta2ndOrder #(
    .WIDTH(8),
    .GROWTH(2)
) 
sigmaDeltaModulator
(
    .clk(clk),
    .rst(rst),
    .en(en),
    .in(signal), ///< [WIDTH-1:0] 
    .sdOut(in)
);

sdMagnitude #(
    .WIDTH(WIDTH),
    .GAIN(GAIN)
)
uut (
    .clk(clk), ///< System Clock
    .rst(rst), ///< Reset, active high & synchronous
    .en(en),   ///< Enable (use to clock at slower rate)
    .in(in),   ///< Sigma-delta input
    .out(out)  ///< [WIDTH-1:0] Magnitude of signal
);

Sinc3Filter #(
    .OSR(16) // Output width is 3*ceil(log2(OSR))+1
)
derp
(
    .clk(clk),
    .en(en), ///< Enable (use to clock at slower rate)
    .in(in),
    .out() ///< [3*$clog2(OSR):0] 
);

endmodule
