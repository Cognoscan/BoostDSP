// Implements a sinc^3 filter on a single-bit input. Useful for sigma-delta 
// modulator outputs. Transfer function is:
//
//          (1-z^-OSR)^3
// H(z) = ----------------
//           (1-z^-1)^3
//
// This is very efficient for Xilinx FPGAs. Also near optimal for any device 
// where long single-bit delay lines can be cheaply implemented. For any other 
// device, it is almost certainly better to implement the 3 accumulators first, 
// decimate, then implement the differentiator stages.

module sinc3Filter #(
    parameter OSR = 16 // Output width is 3*ceil(log2(OSR))+1
)
(
    input clk,
    input en, ///< Enable (use to clock at slower rate)
    input in,
    output reg signed [3*$clog2(OSR):0] out
);

// Parameters
///////////////////////////////////////////////////////////////////////////

parameter ACC_UP = $clog2(OSR)-1; // Must be parameter for Xilinx tools to work.

// Signal Declarations
///////////////////////////////////////////////////////////////////////////

reg signed [3:0] diff;

reg [OSR-1:0] shift0;
reg [OSR-1:0] shift1;
reg [OSR-1:0] shift2;
reg signed [(3+1*ACC_UP):0] acc1 = 'd0;
reg signed [(3+2*ACC_UP):0] acc2 = 'd0;

integer i;

// Main Code
///////////////////////////////////////////////////////////////////////////

// Initialize delay line such that average of all bits in line is 0. Not doing 
// this will result in a non-zero DC offset.
initial begin
    shift0[0] = 1'b1;
    for (i=1; i<OSR; i=i+1) shift0[i] = ~shift0[i-1];
    shift1[0] = ~shift0[OSR-1];
    for (i=1; i<OSR; i=i+1) shift1[i] = ~shift1[i-1];
    shift2[0] = ~shift1[OSR-1];
    for (i=1; i<OSR; i=i+1) shift2[i] = ~shift2[i-1];
    out = 'd0;
end

// diff = (1-z^-OSR) ^ 3
// accumulators implement 1/(1-z^-1)^3
// Vivado Only: assign diff = in - 3*shift[OSR-1] + 3*shift[2*OSR-1] - shift[3*OSR-1];
// ISE requires a case statement sequence to map as efficiently as possible
always @(*) begin
    diff = 4'd0;
    case ({in, shift0[OSR-1], shift1[OSR-1], shift2[OSR-1]})
        4'b0000 : diff =  4'sd0;
        4'b0001 : diff = -4'sd1;
        4'b0010 : diff =  4'sd3;
        4'b0011 : diff =  4'sd2;
        4'b0100 : diff = -4'sd3;
        4'b0101 : diff = -4'sd4;
        4'b0110 : diff =  4'sd0;
        4'b0111 : diff = -4'sd1;
        4'b1000 : diff =  4'sd1;
        4'b1001 : diff =  4'sd0;
        4'b1010 : diff =  4'sd4;
        4'b1011 : diff =  4'sd3;
        4'b1100 : diff = -4'sd2;
        4'b1101 : diff = -4'sd3;
        4'b1110 : diff =  4'sd1;
        4'b1111 : diff =  4'sd0;
    endcase
end

always @(posedge clk) begin
    if (en) begin
        shift0 <= {shift0[OSR-2:0], in};
        shift1 <= {shift1[OSR-2:0], shift0[OSR-1]};
        shift2 <= {shift2[OSR-2:0], shift1[OSR-1]};
        acc1  <= acc1 + diff;
        acc2  <= acc2 + acc1;
        out   <= out  + acc2;
    end
end

endmodule
