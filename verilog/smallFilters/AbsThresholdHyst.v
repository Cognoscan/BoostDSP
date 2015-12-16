/*
* Title: AbsThresholdHyst
*
* Sets a bit on one threshold, and clears it on another. Assumes input data is 
* signed, and looks for absolute value.
*
* To go low to high, abs(inData) must be >= 2^(BIT_HIGH)
* To go high to low, abs(inData) must be < 2^(BIT_LOW)
*
* It will filter out any noise where the amplitude is less than 
* (2^BIT_HIGH - 2^BIT_LOW) / 2.
*
*/

module AbsThresholdHyst #(
    parameter BIT_HIGH = 8, // High threshold
    parameter BIT_LOW  = 7, // Low threshold
    parameter IN_WIDTH = 16
) (
    input clk,                          // Clock for registered bit
    input signed [IN_WIDTH-1:0] inData, // Input signal
    output reg hystDetect               // Detected
);

initial hystDetect = 1'b0;

always @(posedge clk) begin
    hystDetect <= (hystDetect) ? |({(IN_WIDTH-1-BIT_LOW ){inData[IN_WIDTH-1]}} ^ inData[IN_WIDTH-2:BIT_LOW ])
                               : |({(IN_WIDTH-1-BIT_HIGH){inData[IN_WIDTH-1]}} ^ inData[IN_WIDTH-2:BIT_HIGH]);
end


endmodule
