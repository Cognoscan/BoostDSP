module trigTable_tb ();

///////////////////////////////////////////////////////////////////////////
// PARAMETER AND SIGNAL DECLARATIONS
///////////////////////////////////////////////////////////////////////////

wire signed [17:0] sin;
wire signed [17:0] cos;

reg signed [17:0] expectedSin;
reg signed [17:0] expectedCos;
reg [11:0] angle;
reg [11:0] angleD1;
reg clk;

integer i;

///////////////////////////////////////////////////////////////////////////
// MAIN CODE
///////////////////////////////////////////////////////////////////////////

always #1 clk = ~clk;

initial begin
    clk = 1'b0;
    angle = 0;
    angleD1 = 0;
    // Let sine table start outputting valid data
    @(posedge clk);
    @(posedge clk);
    // Run sine table over several frequencies
    for (i=1; i<2**11; i=i<<1) begin // double frequency each time
        @(posedge clk) angle = angle + i;
        while (angle != 0) begin
            @(posedge clk) angle = angle + i;
            if ((sin - expectedSin > 1) || (sin - expectedSin < -1)) begin
                $display("FAILED SIN @ angle=%d", angleD1);
            end
            if ((cos - expectedCos > 1) || (cos - expectedCos < -1)) begin
                $display("FAILED COS @ angle=%d", angleD1);
            end
        end
    end
    $display("PASSED");
    $finish(2);
end

always @(posedge clk) begin
    angleD1 <= angle;
    expectedSin <= $rtoi($floor($sin(($itor(angleD1)+0.5)*2*3.14159/2**12)*(2**17-1)+0.5));
    expectedCos <= $rtoi($floor($cos(($itor(angleD1)+0.5)*2*3.14159/2**12)*(2**17-1)+0.5));
end

trigTable #(
    .ANGLE_WIDTH(12),
    .OUT_WIDTH(18)
) uut (
    .clk(clk),     ///< System Clock
    .angle(angle), ///< [ANGLE_WIDTH-1:0] Angle to take sine of
    .sin(sin),     ///< [OUT_WIDTH-1:0] Sine of angle
    .cos(cos)      ///< [OUT_WIDTH-1:0] Cosine of angle
);

endmodule
