module FileSource_tb ();

// UUT Parameters
parameter FILE_NAME = "out.log";
parameter OUT_WIDTH  = 16;
parameter OUT_NUM    = 8;
parameter CYCLE      = 1;

// UUT Signals
logic clk; ///< System clock
logic rst; ///< Reset, active high and synchronous
logic en;  ///< Enable. Write data to file while high
logic signed [OUT_WIDTH-1:0] dataOut [OUT_NUM]; ///< Signed data from file

// Test Signals
integer fileTest;
integer readback;
integer expected;
logic temp;
logic pass;

// Test Parameters
localparam INCR = (OUT_WIDTH <= 8) ? 1 : 2**(OUT_WIDTH-8);

always #1 clk = ~clk;

initial begin
    $display("Testing FileSource");
    $display("FILE_NAME = %s", FILE_NAME);
    $display("OUT_WIDTH = %d", OUT_WIDTH);
    $display("OUT_NUM   = %d", OUT_NUM  );
    $display("CYCLE     = %d", CYCLE    );
    pass = 1'b1;
    clk = 1'b0;
    rst = 1'b0;
    en = 1'b0;
    @(posedge clk) rst = 1'b1;
    @(posedge clk) rst = 1'b0;
    // Write data out to a file
    fileTest = $fopen(FILE_NAME, "w");
    for (int i=0; i<(2**OUT_WIDTH); i=i+INCR) begin
        $fwrite(fileTest, "%d", i);
        for (int j=1; j<OUT_NUM; j++) begin
            $fwrite(fileTest, ",%d", i+j);
        end
        $fwrite(fileTest, "\n");
    end
    $fclose(fileTest);
    // Read it back and verify it
    @(posedge clk) en = 1'b1;
    for (int i=0; i<(2**(OUT_WIDTH+CYCLE)); i=i+INCR) begin
        @(negedge clk)
        expected = $signed(i[OUT_WIDTH-1:0]);
        readback = dataOut[0];
        if (readback !== expected) begin
            pass = 1'b0;
            $display("FAIL: readback for row=%d, column=%d was %d instead of %d",
                i/INCR, 0, readback, expected);
            $finish();
        end
        for (int j=0; j<OUT_NUM; j++) begin
            expected = i+j;
            expected = $signed(expected[OUT_WIDTH-1:0]);
            readback = dataOut[j];
            if (readback !== expected) begin
                pass = 1'b0;
                $display("FAIL: readback for row=%d, column=%d was %d instead of %d",
                    i/INCR, j, readback, expected);
                $finish();
            end
        end
        wait(clk);
    end
    if (pass) $display("PASS");
    $finish();
end

FileSource #(
    .FILE_NAME(FILE_NAME),
    .OUT_WIDTH(OUT_WIDTH),
    .OUT_NUM  (OUT_NUM  )
    .CYCLE    (CYCLE    )
)
uut (
    .clk(clk), ///< System clock
    .rst(rst), ///< Reset, active high and synchronous
    .en(en),   ///< Enable. Write data to file while high
    .dataOut(dataOut) ///< [OUT_WIDTH-1:0] [OUT_NUM] Signed data from file
);

endmodule
