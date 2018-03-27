module functionGen_tb ();

parameter ARCH = "GENERIC";
parameter BIT_COMPRESS_PHASE = 1;
parameter BIT_COMPRESS_OUTPUT = 1;
parameter OUT_WIDTH = 8;
parameter FREQ_WIDTH = 16;
parameter INCLUDE_CLAMP = 1;

reg clk;
reg rst;
reg en;
reg [1:0] waveType;
reg [FREQ_WIDTH-1:0] freq;
reg [FREQ_WIDTH-1:0] phaseOffset;
reg signed [OUT_WIDTH-1:0] offset;
reg [OUT_WIDTH-1:0] amplitude;
wire signed [OUT_WIDTH-1:0] outSignal;
integer i;

always #1 clk = ~clk;

initial begin
    clk = 1'b0;
    rst = 1'b1;
    en = 1'b1;
    waveType = 2'd0;
    freq = 'd0;
    phaseOffset = 'd0;
    offset = 'd0;
    amplitude = 'd0;
    #10
    rst = 1'b0;
    for (i=0; i<4; i=i+1) begin
        waveType = i;
        freq = 1 << (FREQ_WIDTH-12);
        offset = 'd0;
        amplitude = ~0;
        #20000
        waveType = i;
    end
    waveType = 'd0;
    offset = {2'b01, {OUT_WIDTH-2{1'b0}}}; // 1/2 max positive offset
    #20000
    waveType = 'd0;
    offset = {1'b0, {OUT_WIDTH-1{1'b1}}}; // max positive offset
    #20000
    offset = {1'b1, {OUT_WIDTH-1{1'b0}}}; // max negative offset
    #20000
    offset = 'd0;
    #20000
    $stop(2);
end

functionGen #(
    .ARCH(ARCH),                               ///< System architecture
    .BIT_COMPRESS_PHASE(BIT_COMPRESS_PHASE),   ///< 1 for bit compression, 0 for truncation
    .BIT_COMPRESS_OUTPUT(BIT_COMPRESS_OUTPUT), ///< 1 for bit compression, 0 for truncation
    .OUT_WIDTH(OUT_WIDTH),                     ///< Output word width
    .FREQ_WIDTH(FREQ_WIDTH),                   ///< Input frequency word width
    .INCLUDE_CLAMP(INCLUDE_CLAMP)              ///< Clamp the output to prevent wraparound
)
uut (
    // Inputs
    .clk(clk),                 ///< System clock
    .rst(rst),                 ///< Synchronous reset, active high
    .en(en),                   ///< Output next sample when high
    .waveType(waveType),       ///< [1:0] Waveform type (see top description)
    .freq(freq),               ///< [FREQ_WIDTH-1:0] Frequency
    .phaseOffset(phaseOffset), ///< [FREQ_WIDTH-1;0] Phase offset
    .offset(offset),           ///< [OUT_WIDTH-1:0] Offset value
    .amplitude(amplitude),     ///< [OUT_WIDTH-1:0] Amplitude of waveform
    // Outputs
    .outSignal(outSignal)      ///< [OUT_WIDTH-1:0]
);

endmodule
