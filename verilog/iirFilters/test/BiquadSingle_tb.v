module BiquadSingle_tb ();

reg clk;
reg rst;
reg en;
reg signed [17:0] dataInCos;
reg signed [17:0] dataInSin;
wire signed [17:0] dataOutCos;
wire signed [17:0] dataOutSin;
wire outStrobeCos;
wire outStrobeSin;

real magnitude;
real angle;
real temp;

integer i, j;

localparam MATH_PI = 3.14159;

function real ChirpSin;
    input real k; // In cycles/sample^2
    input integer sample; // Sample number
    ChirpSin = $sin(2*MATH_PI*(k/2 * sample*sample));
endfunction

function real ChirpCos;
    input real k; // In cycles/sample^2
    input integer sample; // Sample number
    ChirpCos = $cos(2*MATH_PI*(k/2 * sample*sample));
endfunction

always #1 clk = ~clk;

initial begin
    clk = 1'b0;
    rst = 1'b1;
    en = 1'b0;
    dataInCos = 'd0;
    dataInSin = 'd0;
    @(posedge clk) @(posedge clk) rst = 1'b0;
    for (i=1; i<65535; i=i+1) begin
        @(posedge clk)
        dataInCos = $rtoi((2**17-1)*ChirpCos(0.000001, i));
        dataInSin = $rtoi((2**17-1)*ChirpSin(0.000001, i));
        en = 1'b1;
        @(posedge clk);
        en = 1'b0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
    end
    $stop();
end

always @(posedge clk) begin
    if (outStrobeSin) begin
        magnitude = 10.0*$log10($hypot(dataOutSin, dataOutCos) / (2.0**17-1));
        temp      = $atan2(dataOutSin, dataOutCos) - $atan2(dataInSin, dataInCos);
        angle     = (temp > 0) ? temp - 2*MATH_PI : temp;
    end
end

BiquadSingle #(
    .WIDTH_D(18),           // Data path width
    .WIDTH_C(18),           // Coeffecient bit width
    .COEFF_B0( 1.22422e-4), // Coeffecient B0
    .COEFF_B1( 2.44844e-4), // Coeffecient B1
    .COEFF_B2( 1.22422e-4), // Coeffecient B2
    .COEFF_A1(-1.97925),    // Coeffecient A1
    .COEFF_A2( 0.97994)     // Coeffecient A2
)
uutSin (
    .clk(clk),
    .rst(rst),
    .inStrobe(en),
    .dataIn(dataInSin), ///< [WIDTH_D-1:0] 
    .outStrobe(outStrobeSin),
    .dataOut(dataOutSin) ///< [WIDTH_D-1:0] 
);

BiquadSingle #(
    .WIDTH_D(18),           // Data path width
    .WIDTH_C(18),           // Coeffecient bit width
    .COEFF_B0( 1.22422e-4), // Coeffecient B0
    .COEFF_B1( 2.44844e-4), // Coeffecient B1
    .COEFF_B2( 1.22422e-4), // Coeffecient B2
    .COEFF_A1(-1.97925),    // Coeffecient A1
    .COEFF_A2( 0.97994)     // Coeffecient A2
)
uutCos (
    .clk(clk),
    .rst(rst),
    .inStrobe(en),
    .dataIn(dataInCos), ///< [WIDTH_D-1:0] 
    .outStrobe(outStrobeCos),
    .dataOut(dataOutCos) ///< [WIDTH_D-1:0] 
);

endmodule
