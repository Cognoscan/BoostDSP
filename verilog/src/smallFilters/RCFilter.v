/*
Title: RCFilter

Filters a single bit using a counter with optional hysteresis. The counter 
increments when bitIn is high and decrements when it is low. bitOut is set when 
bits FILT_WIDTH-1:HYST_BIT of the counter are all high, and clears when they are 
all low. To remove hysteresis, just set HYST_BIT to equal FILT_WIDTH-1.

Parameters:
    input clk     - System Clock
    input rst     - Reset, active high synchronous
    input en      - Sample filter input when high
    input bitIn   - Filter input
    output bitOut - Filter output

*/

module RCFilter #(
    parameter FILT_WIDTH = 8,
    parameter HYST_BIT = 5
)
(
    input clk,        // System Clock
    input rst,        // Reset, active high synchronous
    input en,         // Sample filter input when high
    input bitIn,      // Filter input
    output reg bitOut // Filter output
);

reg [FILT_WIDTH-1:0] counter;

initial begin
    counter <= 'd0;
    bitOut <= 1'b0;
end

always @(posedge clk) begin
    if (rst) begin
        counter <= 'd0;
        bitOut <= 1'b0;
    end
    else if (en) begin
        // Set when all checked bits are 1, clear when all checked bits are 0.
        bitOut <= bitOut ? (|counter[FILT_WIDTH-1:HYST_BIT]) 
                         : (&counter[FILT_WIDTH-1:HYST_BIT]);

        // Counter Logic
        if (~&counter && bitIn) begin // Counter < maximum, count up if bitIn
            counter <= counter + 2'd1;
        end
        else if (|counter && ~bitIn) begin // Counter > 0, count down if ~bitIn
            counter <= counter - 2'd1;
        end
    end
end

endmodule
