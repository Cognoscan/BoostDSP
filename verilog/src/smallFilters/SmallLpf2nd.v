/**
# SmallLpf2nd - 2-pole IIR Low-Pass Filter #

Small 2-pole IIR low-pass filter, made using just adders and bit shifts. Set the 
filter using the K0_SHIFT and K1_SHIFT parameters. It can be slowed down by 
strobing the `en` bit.

```
K0_SHIFT = log2( 2*pi*Fc / Q )
K1_SHIFT = log2( 2*pi*Fc * Q )
```

where `Fc` is the center frequency and `Q` is the quality factor.

*/


module SmallLpf2nd #(
    parameter K0_SHIFT = 8, ///< K0 filter term = 2^-K0_SHIFT
    parameter K1_SHIFT = 8, ///< K1 filter term = 2^-K1_SHIFT
    parameter WIDTH = 16,   ///< Width of data path
    parameter CLAMP = 1     ///< Set to 1 to clamp the accumulators
)
(
    input clk,                        ///< System clock
    input rst,                        ///< Reset, synchronous & active high
    input en,                         ///< Filter strobe
    input  signed [WIDTH-1:0] dataIn, ///< Filter input
    output signed [WIDTH-1:0] dataOut ///< Filter input
);

reg signed [WIDTH+K0_SHIFT-1:0] acc0;
reg signed [WIDTH+K1_SHIFT-1:0] acc1;

wire signed [WIDTH-1:0] acc0Out;
wire signed [WIDTH+K0_SHIFT:0] acc0In;
wire signed [WIDTH+K1_SHIFT:0] acc1In;

assign acc0In = acc0 + dataIn - acc0Out - dataOut;
assign acc1In = acc1 + acc0Out;

always @(posedge clk) begin
    if (rst) begin
        acc0 <= 'd0;
        acc1 <= 'd0;
    end
    else begin
        if (CLAMP) begin
            acc0 <= (^acc0In[WIDTH+K0_SHIFT-:2])
                  ? {acc0In[WIDTH+K0_SHIFT], {(WIDTH+K0_SHIFT-1){acc0In[WIDTH+K0_SHIFT-1]}}}
                  : acc0In;
            acc1 <= (^acc1In[WIDTH+K1_SHIFT-:2])
                  ? {acc1In[WIDTH+K1_SHIFT], {(WIDTH+K1_SHIFT-1){acc1In[WIDTH+K1_SHIFT-1]}}}
                  : acc1In;
        end
        else begin
            acc0 <= acc0In;
            acc1 <= acc1In;
        end
    end
end

assign acc0Out = acc0 >>> K0_SHIFT;
assign dataOut = acc1 >>> K1_SHIFT;

reg clamp0;
reg clamp1;
always @(posedge clk) begin
    if (rst) begin
        clamp0 <= 1'b0;
        clamp1 <= 1'b0;
    end
    else begin
        clamp0 <= clamp0 | (^acc0In[WIDTH+K0_SHIFT-:2]);
        clamp1 <= clamp1 | (^acc1In[WIDTH+K1_SHIFT-:2]);
    end
end

endmodule
