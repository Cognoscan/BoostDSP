module AbsThresholdHyst_tb ();

reg clk;                  // Clock for registered bit
reg signed [15:0] inData; // Input signal
wire hystDetect;          // Detected

integer i;

localparam MAX_RANGE = 2**10;
localparam NOISE = 2**7-1;

always #1 clk = ~clk;

initial begin
    clk = 1'b0;
    inData = 'd0;
    for (i=0; i<MAX_RANGE; i=i+1) begin
        @(posedge clk) #1 inData = i + $signed($random() % NOISE) - NOISE/2;
    end
    for (i=MAX_RANGE; i>-(MAX_RANGE); i=i-1) begin
        @(posedge clk) #1 inData = i + $signed($random() % NOISE) - NOISE/2;
    end
    for (i=-(MAX_RANGE); i<0; i=i+1) begin
        @(posedge clk) #1 inData = i + $signed($random() % NOISE) - NOISE/2;
    end
    $stop();
end

AbsThresholdHyst #(
    .BIT_HIGH(9), // High threshold
    .BIT_LOW(8), // Low threshold
    .IN_WIDTH(16)
)
uut (
    .clk(clk),              // Clock for registered bit
    .inData(inData),        // [IN_WIDTH-1:0] Input signal
    .hystDetect(hystDetect) // Detected
);

endmodule
