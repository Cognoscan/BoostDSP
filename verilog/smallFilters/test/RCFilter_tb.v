module RCFilter_tb ();

reg clk;        // System Clock
reg rst;        // Reset, active high synchronous
reg en;         // Sample filter input when high
reg bitIn;      // Filter input
wire bitOut; // Filter output

integer i;

always #1 clk = ~clk;
initial begin
    clk   = 1'b0;
    rst   = 1'b1;
    en    = 1'b1;
    bitIn = 1'b0;
    #10 rst = 1'b0;
    bitIn = 1'b1;
    wait(bitOut);
    for (i=0; i<1024; i=i+1) begin
        @(posedge clk) #1 bitIn = $random();
    end
    bitIn = 1'b0;
    wait(~bitOut);
    for (i=0; i<1024; i=i+1) begin
        @(posedge clk) #1 bitIn = $random();
    end
    $stop();
end

RCFilter #(
    .FILT_WIDTH(8),
    .HYST_BIT(5)
)
uut (
    .clk(clk),        // System Clock
    .rst(rst),        // Reset, active high synchronous
    .en(en),         // Sample filter input when high
    .bitIn(bitIn),      // Filter input
    .bitOut(bitOut) // Filter output
);

endmodule
