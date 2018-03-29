module SigmaDeltaPhasedArray #(
    parameter NUM_CH     = 64, ///< Number of input channels
    parameter ADDR_WIDTH = 8,  ///< Depth of sample buffers
    parameter OUT_WIDTH  = 16, ///< Width of output signal
    parameter OUT_DELAY  = 3   ///< Specified delay between cmdIn/invertBit and dataOut
)
(
    input clk,
    input rst,
    input sample,
    input [NUM_CH-1:0] dataIn,
    input [NUM_CH*ADDR_WIDTH-1:0] cmdIn, ///< Array of which sample to pull from each channel
    input [NUM_CH-1:0] invertBit, ///< 1 to invert channel bit, 0 to not invert
    output [OUT_WIDTH-1:0] outData
);

localparam NUM_128BUF = (ADDR_WIDTH > 7) ? (1 << (ADDR_WIDTH-7)) : 1;
localparam MUX_ADDR_WIDTH = (ADDR_WIDTH > 7) ? (ADDR_WIDTH-7) : 1;

genvar chIndex;
genvar bufIndex;

integer addrIndex0;
integer addrIndex1;
integer addrIndex2;

reg [ADDR_WIDTH-1:0] bufAddr [NUM_CH-1:0];
reg [6:0] buf128Addr [NUM_CH-1:0];
reg [MUX_ADDR_WIDTH-1:0] muxAddr [NUM_CH-1:0];

always @(*) begin
    for (addr

if (OUT_DELAY > 3) begin
    always @(posedge clk) begin
        for (addrIndex=0; addrIndex<NUM_CH; addrIndex=addrIndex+1) begin
            buf128Addr <= cmdIn[(addrIndex*ADDR_WIDTH)+:ADDR_WIDTH];
        end
    end
end

// Generate the 128 sample deep buffers
generate
    for (chIndex=0;chIndex<NUM_CH; chIndex=chIndex+1) begin
        for (bufIndex=0; bufIndex<NUM_128BUF; bufIndex=bufIndex+1) begin
            SigmaDeltaPhasedArray128Buf sampleBuffer (
                .clk(clk),
                .sample(sample),
                .shiftIn(shiftArray[chIndex][bufIndex]),
                .addr(buf128Addr[chIndex]),                 ///< [6:0] 
                .shiftOut(shiftArray[chIndex][bufIndex+1]),
                .dataOut(buf128Out[chIndex][bufIndex])
            );
        end
    end
endgenerate


endmodule

module SigmaDeltaPhasedArray128Buf (
    input clk,
    input sample,
    input shiftIn,
    input [6:0] addr,
    output shiftOut,
    output dataOut
);

reg [127:0] shiftReg;

assign dataOut = shiftReg[addr];
assign shiftOut = shiftReg[127];

always @(posedge clk) begin
    if (sample) begin
        shiftReg <= {shiftReg[126:0], shiftIn};
    end
end

endmodule
