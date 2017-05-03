module FileSink_tb ();

// UUT Parameters
parameter FILE_NAME = "out.log";
parameter IN_WIDTH  = 8;
parameter IN_NUM    = 4;

// UUT Signals
logic clk;    ///< System clock
logic rst;    ///< Reset, active high and synchronous
logic en;     ///< Enable. Write data to file while high
logic closed; ///< Set high to close file. MUST use only at end of simulation
logic signed [IN_WIDTH-1:0] dataIn [IN_NUM]; ///< Signed data to write to file

// Test Signals
integer fileTest;
integer readback;
integer expected;
logic temp;
logic pass;

// Test Parameters
localparam INCR = (IN_WIDTH <= 8) ? 1 : 2**(IN_WIDTH-8);

always #1 clk = ~clk;

initial begin
    pass = 1'b1;
    clk = 1'b0;
    rst = 1'b0;
    en = 1'b0;
    closed = 1'b0;
    @(posedge clk) rst = 1'b1;
    @(posedge clk) rst = 1'b0;
    // Write data out to a file
    for (int i=0; i<(2**IN_WIDTH); i=i+INCR) begin
        @(posedge clk)
        en = 1'b1;
        for (int j=0; j<IN_NUM; j++) begin
            dataIn[j] = i+j;
        end
        wait(~clk);
    end
    @(posedge clk) closed = 1'b1;
    @(posedge clk) closed = 1'b1;
    // Read it back and verify it
    fileTest = $fopen(FILE_NAME, "r");
    for (int i=0; i<(2**IN_WIDTH); i=i+INCR) begin
        temp = $fscanf(fileTest, "  %d", readback);
        expected = $signed(i[IN_WIDTH-1:0]);
        if (readback !== expected) begin
            pass = 1'b0;
            $display("FAIL: readback for row=%d, column=%d was %d instead of %d",
                i/INCR, 0, readback, expected);
            $finish();
        end
        for (int j=1; j<IN_NUM; j++) begin
            temp = $fscanf(fileTest, " , %d", readback);
            expected = i+j;
            expected = $signed(expected[IN_WIDTH-1:0]);
            if (readback !== expected) begin
                pass = 1'b0;
                $display("FAIL: readback for row=%d, column=%d was %d instead of %d",
                    i/INCR, j, readback, expected);
                $finish();
            end
        end
    end
    if (pass) $display("PASS");
    $finish();
end



FileSink #(
    .FILE_NAME(FILE_NAME),
    .IN_WIDTH (IN_WIDTH ),
    .IN_NUM   (IN_NUM   )
)
uut (
    .clk(clk),       ///< System clock
    .rst(rst),       ///< Reset, active high and synchronous
    .en(en),         ///< Enable. Write data to file while high
    .closed(closed), ///< Set high to close file. MUST use only at end of simulation
    .dataIn(dataIn)  ///< Signed data to write to file
);

endmodule
