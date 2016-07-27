/**
# SmallHpf2nd - 2-pole IIR High-Pass Filter #

Small 2-Pole IIR high-pass filter, made using just adders and bit shifts. Set 
the frequency using the K0_SHIFT and K1_SHIFT parameters. It can be slowed down 
by strobing the `en` bit to run at a lower rate.

By using power of two feedback terms, this filter is alsways stable and is 
immune to limit cycling.

Clamping is necessary if the full input range will be used. Clamping is 
unnecessary if the input word will never go beyond '+/- (2^(WIDTH-2)-1)'. Keep 
in mind that clamping will cause nonlinear distortion in high-amplitude signals.

## Design Equations ##

Let w0 be the desired cutoff frequency in radians/second, let f_clk be the 
filter run rate (defined by clk and en), and let Q be the desired quality 
factor.

```
                s^2
H(s) = -----------------------
        s^2 + (w0/Q)*s + w0^2

w0 = 2*pi*f0

K0_SHIFT = -log2(w0/Q / f_clk)
K1_SHIFT  = -log2(w0*Q / f_clk)

w0/Q = 2^-K0_SHIFT * f_clk
w0*Q = 2^-K1_SHIFT  * f_clk

w0 = sqrt(2^-K0_SHIFT * 2^-K1_SHIFT * f_clk^2)
Q  = sqrt(2^-K1_SHIFT / 2^-K0_SHIFT)
```

Since the SHIFT parameters must be integers, the final filter will not perfectly 
match the desired one. The true filter response will also be different from the 
continuous-time approximation.

## Block Diagram ##

Key:
- ACCUM: accumulator
- SUB: subtract signal on bottom from the signal on the left
- 2^-X: Right arithmetic shift by X

```

dataIn --->(SUB)--->(SUB)------------------------------+--> dataOut
             ^        ^                                |
             |        |                                |
             |        +----[2^-K0_SHIFT]<---[ACCUM]<---/
             |        |
             |        \--------------------------------\
             |                                         |
             \-------------[2^-K1_SHIFT]<---[ACCUM]<---/

```


*/


module SmallHpf2nd #(
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
reg signed [WIDTH-1:0] forwardPath;

wire signed [WIDTH-1:0] acc0Out;
wire signed [WIDTH-1:0] acc1Out;
wire signed [WIDTH+K0_SHIFT:0] acc0In;
wire signed [WIDTH+K1_SHIFT:0] acc1In;

assign acc0In = acc0 + dataOut;
assign acc1In = acc1 + acc0Out;

always @(posedge clk) begin
    if (rst) begin
        forwardPath <= 'd0;
        acc0        <= 'd0;
        acc1        <= 'd0;
    end
    else if (en) begin
        forwardPath <= dataIn - acc0Out - acc1Out;
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

assign dataOut = forwardPath;
assign acc0Out = acc0 >>> K0_SHIFT;
assign acc1Out = acc1 >>> K1_SHIFT;

// Test Code: Check to see if clamping ever occurs
/*
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
*/

endmodule
