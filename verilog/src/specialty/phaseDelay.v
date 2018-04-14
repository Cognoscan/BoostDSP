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

///////////////////////////////////////////////////////////////////////////
// PARAMETER DECLARATIONS
///////////////////////////////////////////////////////////////////////////

initial begin
    if ((2**OUT_WIDTH-1) < NUM_CH) begin
        $display("Attribute OUT_WIDTH on phaseDelay instance %m is %i. Must be at least %i (log2(NUM_CH+1)).", OUT_WIDTH, $log2(NUM_CH+1));
        #1 $finish;
    end
end

parameter SUM_DEPTH = $rtoi($ceil($log10(NUM_CH/3.0)/$log10(3.0)));
parameter NUM_SUMS = 3**SUM_DEPTH;

localparam NUM_128BUF = (ADDR_WIDTH > 7) ? (1 << (ADDR_WIDTH-7)) : 1;
localparam MUX_ADDR_WIDTH = (ADDR_WIDTH > 7) ? (ADDR_WIDTH-7) : 1;

///////////////////////////////////////////////////////////////////////////
// SIGNAL DECLARATIONS
///////////////////////////////////////////////////////////////////////////

genvar chIndex;
genvar bufIndex;
integer sumIndex;

integer addr128Index;
integer addrIndex;
integer muxIndex;

reg [NUM_SUMS*2-1:0] sumsReg;
reg [NUM_SUMS*2-1:0] sums;
reg [ADDR_WIDTH-1:0] bufAddr [NUM_CH-1:0];
reg [6:0] buf128Addr [NUM_CH-1:0];
reg [MUX_ADDR_WIDTH-1:0] muxAddr [NUM_CH-1:0];
wire [NUM_128BUF:0] shiftArray [NUM_CH-1:0];
reg [NUM_CH-1:0] invertBitBuf;
reg [NUM_CH-1:0] invertBitD1;

reg [NUM_128BUF-1:0] buf128Out [NUM_CH-1:0];
reg [NUM_CH-1:0] bufOut;

///////////////////////////////////////////////////////////////////////////
// BUFFERS & ADDRESS LOGIC
///////////////////////////////////////////////////////////////////////////

// Split up the inputs & optionally delay them
if (OUT_DELAY > SUM_DEPTH+2) begin
    always @(posedge clk) begin
        invertBitD1 <= invertBit;
        for (addrIndex=0; addrIndex<NUM_CH; addrIndex=addrIndex+1) begin
            bufAddr[addrIndex] <= cmdIn[(addrIndex*ADDR_WIDTH)+:ADDR_WIDTH];
        end
    end
end
else begin
    always @(*) begin
        invertBitD1 = invertBit;
        for (addrIndex=0; addrIndex<NUM_CH; addrIndex=addrIndex+1) begin
            bufAddr[addrIndex] = cmdIn[(addrIndex*ADDR_WIDTH)+:ADDR_WIDTH];
        end
    end
end

if (OUT_DELAY > SUM_DEPTH+1) begin
    always @(posedge clk) invertBitBuf <= invertBitD1;
end
else begin
    always @(*) invertBitBuf = invertBitD1;
end

// Get the buf128 addresses
always @(*) begin
    for (addr128Index=0; addr128Index<NUM_CH; addr128Index=addr128Index+1) begin
        buf128Addr[addr128Index] = bufAddr[addr128Index];
    end
end

// Generate the 128 sample deep buffers
generate
    for (chIndex=0;chIndex<NUM_CH; chIndex=chIndex+1) begin
        assign shiftArray[chIndex][0] = dataIn[chIndex];
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

// Multiplexers to select from the sample buffers
if (NUM_128BUF == 1) begin
    if (OUT_DELAY > SUM_DEPTH+1) begin
        always @(posedge clk) begin
            for (muxIndex=0; muxIndex<NUM_CH; muxIndex=muxIndex+1) begin
                bufOut[muxIndex] <= buf128Out[muxIndex][0];
            end
        end
    end
    else begin
        always @(*) begin
            for (muxIndex=0; muxIndex<NUM_CH; muxIndex=muxIndex+1) begin
                bufOut[muxIndex] <= buf128Out[muxIndex][0];
            end
        end
    end
end
else begin
    if (OUT_DELAY > SUM_DEPTH+1) begin
        always @(posedge clk) begin
            for (muxIndex=0; muxIndex<NUM_CH; muxIndex=muxIndex+1) begin
                bufOut[muxIndex] <= buf128Out[muxIndex][bufAddr[muxIndex][ADDR_WIDTH-1:7]];
            end
        end
    end
    else begin
        always @(*) begin
            for (muxIndex=0; muxIndex<NUM_CH; muxIndex=muxIndex+1) begin
                bufOut[muxIndex] <= buf128Out[muxIndex][bufAddr[muxIndex][ADDR_WIDTH-1:7]];
            end
        end
    end
end

///////////////////////////////////////////////////////////////////////////
// SUMMATION
///////////////////////////////////////////////////////////////////////////

// Sum 3 bits
always @(*) begin
    sums = 'd0;
    for (sumIndex=0; sumIndex<NUM_CH/3; sumIndex=sumIndex+1) begin
        sums[sumIndex] = (invertBitBuf[sumIndex+0] ^ bufOut[sumIndex+0])
                       ^ (invertBitBuf[sumIndex+1] ^ bufOut[sumIndex+1])
                       ^ (invertBitBuf[sumIndex+2] ^ bufOut[sumIndex+2]);
        sums[sumIndex+1] = (invertBitBuf[sumIndex+0] ^ bufOut[sumIndex+0]) & (invertBitBuf[sumIndex+1] ^ bufOut[sumIndex+1])
                         | (invertBitBuf[sumIndex+1] ^ bufOut[sumIndex+1]) & (invertBitBuf[sumIndex+2] ^ bufOut[sumIndex+2])
                         | (invertBitBuf[sumIndex+2] ^ bufOut[sumIndex+2]) & (invertBitBuf[sumIndex+0] ^ bufOut[sumIndex+0]);
    end
    if (NUM_CH % 3 == 1) begin
        sums[(NUM_CH/3)*2-2] = (invertBitBuf[NUM_CH-1] ^ bufOut[NUM_CH-1]);
        sums[(NUM_CH/3)*2-1] = 1'b0;
    end
    else if (NUM_CH % 3 == 2) begin
        sums[(NUM_CH/3)*2-2] = (invertBitBuf[NUM_CH-2] ^ bufOut[NUM_CH-2])
                             ^ (invertBitBuf[NUM_CH-1] ^ bufOut[NUM_CH-1]);
        sums[(NUM_CH/3)*2-1] = (invertBitBuf[NUM_CH-2] ^ bufOut[NUM_CH-2])
                             & (invertBitBuf[NUM_CH-1] ^ bufOut[NUM_CH-1]);
    end
end

// Register sums if necessary
if (OUT_DELAY > SUM_DEPTH) begin
    always @(posedge clk) sumsReg <= sums;
end
else begin
    always @(*) sumsReg = sums;
end

// Nested summations
if (SUM_DEPTH >= 1) begin
    // At least 4 channels exist - sum them
    reg [3:0] sum3 [NUM_SUMS/3-1:0];
    integer sum3Index;
    if (OUT_DELAY > SUM_DEPTH-1) begin
        always @(posedge clk) begin
            for (sum3Index=0; sum3Index<NUM_SUMS/3; sum3Index=sum3Index+1) begin
                sum3[sum3Index] <= sumsReg[3*sum3Index+:2] + sumsReg[3*sum3Index+1+:2] + sumsReg[3*sum3Index+2+:2];
            end
        end
        always @(*) begin
            for (sum3Index=0; sum3Index<NUM_SUMS/3; sum3Index=sum3Index+1) begin
                sum3[sum3Index] = sumsReg[3*sum3Index+:2] + sumsReg[3*sum3Index+1+:2] + sumsReg[3*sum3Index+2+:2];
            end
        end
    end

    // At least 10 channels exist - sum them
    if (SUM_DEPTH >= 2) begin
        reg [4:0] sum9 [NUM_SUMS/9-1:0];
        integer sum9Index;
        if (OUT_DELAY > SUM_DEPTH-2) begin
            always @(posedge clk) begin
                for (sum9Index=0; sum9Index<NUM_SUMS/9; sum9Index=sum9Index+1) begin
                    sum9[sum9Index] <= sum3[sum9Index] + sum3[sum9Index+1] + sum3[sum9Index+2];
                end
            end
        end
        else begin
            always @(*) begin
                for (sum9Index=0; sum9Index<NUM_SUMS/9; sum9Index=sum9Index+1) begin
                    sum9[sum9Index] = sum3[sum9Index] + sum3[sum9Index+1] + sum3[sum9Index+2];
                end
            end
        end

        // At least 28 channels exist - sum them
        if (SUM_DEPTH >= 3) begin
            reg [6:0] sum27 [NUM_SUMS/27-1:0];
            integer sum27Index;
            if (OUT_DELAY > SUM_DEPTH-3) begin
                always @(posedge clk) begin
                    for (sum27Index=0; sum27Index<NUM_SUMS/27; sum27Index=sum27Index+1) begin
                        sum27[sum27Index] <= sum9[sum27Index] + sum9[sum27Index+1] + sum9[sum27Index+2];
                    end
                end
            end
            else begin
                always @(*) begin
                    for (sum27Index=0; sum27Index<NUM_SUMS/27; sum27Index=sum27Index+1) begin
                        sum27[sum27Index] = sum9[sum27Index] + sum9[sum27Index+1] + sum9[sum27Index+2];
                    end
                end
            end

            // At least 82 channels exist - sum them
            // This supports up to 243 channels
            if (SUM_DEPTH >= 4) begin
                reg [7:0] sum81;
                if (OUT_DELAY >= 1) begin
                    always @(posedge clk) begin
                        sum81 <= sum27[0] + sum27[1] + sum27[2];
                    end
                end
                else begin
                    always @(*) begin
                        sum81 = sum27[0] + sum27[1] + sum27[2];
                    end
                end
                assign outData = sum81;
            end
            else begin
                assign outData = sum27[0];
            end
        end
        else begin
            assign outData = sum9[0];
        end
    end
    else begin
        assign outData = sum3[0];
    end
end
else begin
    assign outData = sums[1:0];
end


endmodule

///////////////////////////////////////////////////////////////////////////
// BUFFER SUBMODULE
///////////////////////////////////////////////////////////////////////////

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
