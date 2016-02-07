module functionGen_tb ();

reg clk;
reg rst;
reg en;
reg [1:0] waveType;
reg [7:0] freq;
reg signed [7:0] offset;
reg [7:0] amplitude;
wire signed [7:0] outSignal;
integer i;

always #1 clk = ~clk;

initial begin
    clk = 1'b0;
    rst = 1'b1;
    en = 1'b1;
    waveType = 2'd0;
    freq = 'd0;
    offset = 'd0;
    amplitude = 'd0;
    #10
    rst = 1'b0;
    for (i=0; i<4; i=i+1) begin
        waveType = i;
        freq = 'd1;
        offset = 'd0;
        amplitude = ~0;
        #1000
        waveType = i;
    end
    waveType = 'd0;
    offset = 8'h40;
    amplitude = ~0;
    #1000
    waveType = 'd0;
    offset = 8'h7F;
    amplitude = ~0;
    #1000
    offset = 8'h80;
    amplitude = ~0;
    #1000
    offset = 8'h00;
    amplitude = 1;
    #1000
    $stop(2);
end

functionGen #(
    .OUT_WIDTH(8),      // Output word width
    .FREQ_WIDTH(8),     // Input frequency word width
    .INCLUDE_CLAMP(1'b1) // Clamp the output to prevent wraparound
)
uut (
    // Inputs
    .clk(clk),                       // System clock
    .rst(rst),                       // Synchronous reset, active high
    .en(en),                        // Output next sample when high
    .waveType(waveType),             ///< [1:0] // Waveform type (see top description)
    .freq(freq),      ///< [FREQ_WIDTH-1:0] // Frequency
    .offset(offset),     ///< [OUT_WIDTH-1:0] // Offset value
    .amplitude(amplitude),  ///< [OUT_WIDTH-1:0] // Amplitude of waveform
    // Outputs
    .outSignal(outSignal) ///< [OUT_WIDTH-1:0] 
);

endmodule
