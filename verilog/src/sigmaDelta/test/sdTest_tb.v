module sdTest_tb ();

parameter WIDTH = 16;
parameter GAIN = 9;

// UUT Signals
reg clk;              ///< System Clock
reg rst;              ///< Reset, active high & synchronous
reg en;               ///< Enable (use to clock at slower rate)
wire in;              ///< Sigma-delta input
wire [WIDTH-1:0] out; ///< Magnitude of signal

// Testbench Signals
reg signed [15:0] signal;
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
    #10000 signal = 16'sd32767;
    #10000 signal = -16'sd32768;
    #10000 signal = 16'sd16384;
    #10000 signal = -16'sd16384;
    #10000 signal = 0;
    for (i=0; i<32767; i=i+16) begin
        //#100 signal = i;
        #100 signal = $rtoi($ln($itor(i)/3276.7+1.0)/$ln(10.0)*32767);
    end
    for (i=0; i<2**13; i=i+1) begin
        #100 signal = $rtoi(32767.0*$sin(3.141259*2.0*($itor(i)/2.0**10 + $itor(i)**2/2.0**17)));
    end
    #10000 $stop();
end

integer testFunc;
integer testFunc2;
integer testFunc3;
real testFunc4;
always @(posedge clk) testFunc = $sqrt(testFunc2);
always @(posedge clk) testFunc2 = (signal > 0) ? signal : -signal;
always @(posedge clk) testFunc3 = signal**2;
always @(posedge clk) testFunc4 = $ln($itor(out));

SigmaDelta2ndOrder #(
    .WIDTH(16),
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

sdTest #(
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

endmodule
