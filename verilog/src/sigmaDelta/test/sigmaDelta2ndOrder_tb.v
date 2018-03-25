module sigmaDelta2ndOrder_tb ();

parameter WIDTH = 16;
parameter GAIN = 9;

// UUT Signals
reg clk;              ///< System Clock
reg rst;              ///< Reset, active high & synchronous
reg en;               ///< Enable (use to clock at slower rate)
reg signed [15:0] in;
wire sdOut;           ///< Sigma-delta input

// Testbench Signals
wire [WIDTH-1:0] out; ///< Magnitude of in
integer i;

always #1 clk = ~clk;

initial begin
    clk    = 1'b0;
    rst    = 1'b1;
    en     = 1'b1;
    in = 'd0;
    @(posedge clk) rst = 1'b1;
    @(posedge clk) rst = 1'b1;
    @(posedge clk) rst = 1'b0;
    #10000 in = 16'sd32767;
    #10000 in = -16'sd32768;
    #10000 in = 16'sd16384;
    #10000 in = -16'sd16384;
    #10000 in = 0;
    for (i=0; i<32767; i=i+16) begin
        //#100 in = i;
        #100 in = $rtoi($ln($itor(i)/3276.7+1.0)/$ln(10.0)*32767);
    end
    for (i=0; i<2**13; i=i+1) begin
        #100 in = $rtoi(32767.0*$sin(3.141259*2.0*($itor(i)/2.0**10 + $itor(i)**2/2.0**17)));
    end
    #10000 $stop();
end

sigmaDelta2ndOrder #(
    .WIDTH(16),
    .GROWTH(3)
) 
uut (
    .clk(clk),
    .rst(rst),
    .en(en),
    .in(in), ///< [WIDTH-1:0] 
    .sdOut(sdOut)
);

sinc3Filter #(
    .OSR(32) // Output width is 3*ceil(log2(OSR))+1
)
filterOut (
    .clk(clk),
    .en(en), ///< Enable (use to clock at slower rate)
    .in(sdOut),
    .out(out) ///< [3*$clog2(OSR):0] 
);

endmodule
