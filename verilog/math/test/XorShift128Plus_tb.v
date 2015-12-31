module XorShift128Plus_tb ();

reg [127:0] seed;
reg         clk;
reg         rst;
reg         seedStrobe;
reg         read;

wire        randomReady;
wire [63:0] randomValue;

integer i;
integer failures;

reg [63:0] testVector [0:99];
reg [63:0] testValue;

always #1 clk = ~clk;


initial begin
    seed = {64'd2, 64'd1};
    clk = 1'b0;
    rst = 1'b1;
    seedStrobe = 1'b0;
    read = 1'b0;
    #11 rst = 1'b0;

    $readmemh("./math/test/testVector.txt", testVector);

    @(posedge clk) seedStrobe = 1'b0;
    @(posedge clk) seedStrobe = 1'b1;
    @(posedge clk) seedStrobe = 1'b0;
    @(posedge clk) seedStrobe = 1'b0;
    failures = 0;
    for (i=0; i<100; i=i+1) begin
        wait(randomReady);
        read = 1'b1;
        testValue = testVector[i];
        if (testValue != randomValue) failures = failures + 1;
        @(posedge clk) read = 1'b1;
        @(posedge clk) read = 1'b1;
    end

    if (failures == 0) begin
        $display("PASSED");
    end
    else begin
        $display("FAILED");
        $display("Failures: %d / 100", failures);
    end
    $stop();
end

XorShift128Plus uut (
    .clk(clk),
    .rst(rst),
    .seed(seed),               ///< [127:0]
    .seedStrobe(seedStrobe),
    .read(read),
    .randomReady(randomReady),
    .randomValue(randomValue)  ///< [63:0]
);

endmodule
