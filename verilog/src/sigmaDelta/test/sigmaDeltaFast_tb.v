module SigmaDeltaFast_tb ();

parameter WIDTH = 4;
parameter OUTLEN = (1 << WIDTH);

// UUT Signals
reg clk;                   ///< System Clock
reg rst;                   ///< Reset, active high & synchronous
reg en;                    ///< Enable (use to clock at slower rate)
reg signed [WIDTH-1:0] in;
wire [OUTLEN-1:0] sdOut;   ///< Sigma-delta output

// Testbench Signals
wire sdOutComp;  ///< Sigma-delta value for comparison
wire [15:0] out; ///< Sinc^3 filtered version of sdOut
reg [OUTLEN-1:0] shiftReg;
integer i;
integer enCount;

always #1 clk = ~clk;

// Strobe every OUTLEN cycles
always @(posedge clk) begin
    if (enCount == 0) begin 
        enCount = OUTLEN-1;
        en = 1'b1;
        shiftReg = sdOut;
    end
    else begin
        enCount = enCount - 1;
        en = 1'b0;
        shiftReg = shiftReg >> 1;
    end
end

initial begin
    shiftReg = 32'hAAAA_AAAA;
    enCount = 'd0;
    clk    = 1'b0;
    rst    = 1'b1;
    en     = 1'b0;
    in = 'd0;
    @(posedge clk) rst = 1'b1;
    @(posedge clk) rst = 1'b1;
    @(posedge clk) rst = 1'b0;
    #10000 in =  (2**(WIDTH-1))-1;
    #10000 in = -(2**(WIDTH-1));
    #10000 in =  (2**(WIDTH-2));
    #10000 in = -(2**(WIDTH-2));
    #10000 in = 0;
    for (i=0; i<2**18; i=i+1) begin
        @(posedge en) in = $rtoi((2.0**(WIDTH-1)-1)*$sin(3.141259*2.0*($itor(i)/2.0**15 + $itor(i)**2/2.0**22)));
    end
    #10000 $stop();
end

SigmaDeltaFast #(
    .WIDTH(WIDTH),
    .OUTLEN(OUTLEN)
)
uut (
    .clk(clk),    ///< System clock
    .rst(rst),    ///< Reset, synchronous active high
    .en(en),      ///< Enable to run the modulator
    .in(in),      ///< [WIDTH-1:0] Input to modulator
    .sdOut(sdOut) ///< [OUTLEN-1:0] Sigma delta stream, LSB=first sample, MSB=last sample
);

SigmaDelta1stOrder #(
    .WIDTH(WIDTH)
) 
comparison (
    .clk(clk),
    .rst(rst),
    .en(1'b1),
    .in(in), ///< [WIDTH-1:0] 
    .sdOut(sdOutComp)
);

Sinc3Filter #(
    .OSR(32) // Output width is 3*ceil(log2(OSR))+1
)
filterOut (
    .clk(clk),
    .en(1'b1), ///< Enable (use to clock at slower rate)
    .in(shiftReg[0]),
    .out(out) ///< [3*$clog2(OSR):0] 
);

endmodule
