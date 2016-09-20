module sdAverage_tb ();

// UUT Signals
reg clk;    ///< System Clock
reg rst;    ///< Reset, synchronous and active high
reg en;     ///< Enable for sigma-delta
wire in0;   ///< Sigma-delta input 0
wire in1;   ///< Sigma-delta input 1
wire sdAvg; ///< Averaged result

// Test signals

reg signed [3:0] sdCmd0;
reg signed [3:0] sdCmd1;

initial begin
    clk = 1'b0;
    rst = 1'b1;
    en = 1'b1;
    sdCmd0 = -8;
    sdCmd1 = -8;
    @(posedge clk) rst = 1'b1;
    @(posedge clk) rst = 1'b1;
    @(posedge clk) rst = 1'b0;
    #100
    sdCmd0 = -8;
    sdCmd1 = 0;
    #100
    sdCmd0 = 0;
    sdCmd1 = -8;
    #100
    sdCmd0 = 0;
    sdCmd1 = 0;
    #100
    sdCmd0 = 7;
    sdCmd1 = 0;
    #100
    sdCmd0 = 0;
    sdCmd1 = 7;
    #100
    sdCmd0 = 7;
    sdCmd1 = 7;
    #100
    sdCmd0 = 7;
    sdCmd1 = -8;
    #100
    sdCmd0 = -8;
    sdCmd1 = 7;
    #100
    $stop;
end

always #1 clk = ~clk;
sdDac #(4) sd0 (.clk(clk), .rst(rst), .en(en), .in(sdCmd0), .dac(in0));
sdDac #(4) sd1 (.clk(clk), .rst(rst), .en(en), .in(sdCmd1), .dac(in1));

sdAverage uut
(
    .clk(clk),   ///< System Clock
    .rst(rst),   ///< Reset, synchronous and active high
    .en(en),    ///< Enable for sigma-delta
    .in0(in0),   ///< Sigma-delta input 0
    .in1(in1),   ///< Sigma-delta input 1
    .sdAvg(sdAvg) ///< Averaged result
);


endmodule
