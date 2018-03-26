module SigmaDelta1stOrder_tb ();

parameter IS_LIMITED = 1;
parameter OUT_WIDTH = 8;
parameter IN_WIDTH = 16;

// UUT Signals
reg clk;                    ///< System Clock
reg rst;                    ///< Reset, active high & synchronous
reg en;                     ///< Enable (use to clock at slower rate)
reg signed [IN_WIDTH-1:0] in;
wire [OUT_WIDTH-1:0] sdOut; ///< Sigma-delta input
wire sdOut2;

// Testbench Signals
wire [IN_WIDTH-1:0] out; ///< Magnitude of in
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
    #10000 in =  (2**(IN_WIDTH-1))-1;
    #10000 in =  {1'b0, {OUT_WIDTH-1{1'b1}}, {IN_WIDTH-OUT_WIDTH{1'b0}}};
    #10000 in =  {1'b0, {OUT_WIDTH-2{1'b1}}, 1'b0, {IN_WIDTH-OUT_WIDTH{1'b1}}};
    #10000 in =  (2**(IN_WIDTH-2));
    #10000 in = -(2**(IN_WIDTH-2));
    #10000 in =  {1'b1, {OUT_WIDTH-1{1'b0}}, {IN_WIDTH-OUT_WIDTH{1'b1}}};
    #10000 in = -(2**(IN_WIDTH-1));
    #10000 
    for (i=-(2**15); i<2**15; i=i+1) begin
        @(posedge clk) in = i[15:0];
    end
    for (i=0; i<2**18; i=i+1) begin
        @(posedge clk) in = $rtoi((2.0**(IN_WIDTH-2))*$sin(3.141259*2.0*($itor(i)/2.0**15 + $itor(i)**2/2.0**22)));
    end
    #10000 $stop();
end

SigmaDelta1stOrder #(
    .IS_LIMITED(IS_LIMITED),
    .IN_WIDTH(IN_WIDTH),
    .OUT_WIDTH(OUT_WIDTH)
) 
uut (
    .clk(clk),
    .rst(rst),
    .en(en),
    .in(in), ///< [IN_WIDTH-1:0] 
    .sdOut(sdOut)
);

SigmaDelta1stOrder #(
    .IS_LIMITED(0),
    .IN_WIDTH(IN_WIDTH),
    .OUT_WIDTH(1)
) 
uut2 (
    .clk(clk),
    .rst(rst),
    .en(en),
    .in(in), ///< [IN_WIDTH-1:0] 
    .sdOut(sdOut2)
);

Sinc3Filter #(
    .OSR(32) // Output width is 3*ceil(log2(OSR))+1
)
filterOut (
    .clk(clk),
    .en(en), ///< Enable (use to clock at slower rate)
    .in(sdOut2),
    .out(out) ///< [3*$clog2(OSR):0] 
);

endmodule
