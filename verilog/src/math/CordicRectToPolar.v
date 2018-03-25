/**
# CordicRectToPolar - CORDIC Algorithm for Rectangular to Polar Coordinates #

Implements the CORDIC algorithm for the purpose of converting rectangular 
coordinates to polar coordinates. It takes N cycles, where 
`N = min(IN_WIDTH, ANGLE_WIDTH-1)`.

## Algorithm ## 

The algorithm is based on doing iterative rotations of the x & y coordinates 
using specially chosen angles. Rotation is done towards the positive X axis. 
When complete, the X coordinate will equal the polar coordinate magnitude times 
a constant, and the total rotation angle will be the polar coordinate angle.

```
[ cos(t)  -sin(t) ] =  (1+tan(t)^2)^(-1/2) * [   1    -tan(t) ]
[ sin(t)   cos(t) ]                          [ tan(t)    1    ]

Choose t such that tan(t) = 2^-i, where i is the iteration number:

= (1+2^(-2*i))^(-1/2) * [  1    -2^-i ]
                        [ 2^-i    1   ]
```

The maximum number of rotations can be determined by how many bits are in the 
input word and the output angle. When the bit shift implied by the `2^-i` amount 
would be greater than the input word width, the algorithm would be adding +/- 0, 
so it can terminate. Likewise, when the angle value in the lookup table is 
smaller than the LSB of the output angle word, the algorithm would be adding +/- 
0 to it, so it can terminate.

## Steps ##

1. Rotate coordinate into quadrant 1 (positive x, positive y)
2. Rotate using powers of two and a lookup table for the angle used.
3. Terminate when no more bits can be computed.

## Notes ##

1. This algorithm will not complete if inStrobe is set more than once every ITER_NUM cycles.
2. No optimizations are applied - there are no attempts to fit into DSP device primitives.

*/

module CordicRectToPolar #(
    parameter STAGES          = 1,  ///< Number of stages in CORDIC
    parameter IN_WIDTH        = 16, ///< Input coordinate pair width
    parameter ANGLE_WIDTH     = 16, ///< Output angle register width
    parameter SCALE_MAGNITUDE = 0,  ///< Set to 1 to scale magnitude to true value
    parameter MULT_WIDTH      = 16  ///< Number of bits to use for magnitude scaling word, if SCALE_MAGNITUDE is 1
)
(
    input                                clk,       ///< System clock
    input                                rst,       ///< Reset, active high and synchronous
    input                                inStrobe,  ///< Input data strobe
    input       signed [IN_WIDTH-1:0]    x,         ///< X coordinate
    input       signed [IN_WIDTH-1:0]    y,         ///< Y coordinate
    output reg         [ANGLE_WIDTH-1:0] angle,     ///< Angle
    output reg         [IN_WIDTH:0]      magnitude, ///< Magnitude
    output reg                           outStrobe  ///< Output data strobe
);

//////////////////////////////////////////////////////////////////////////////
// Local Parameters (do not set externally)
//////////////////////////////////////////////////////////////////////////////
parameter ITER_NUM   = (IN_WIDTH > (ANGLE_WIDTH-1)) ? (ANGLE_WIDTH-1) : IN_WIDTH;
parameter ITER_WIDTH = $clog2(ITER_NUM);
parameter M_PI       = $acos(-1.0);

localparam STAGES_INT = (ITER_NUM > STAGES) ? STAGES : ITER_NUM; // Max out at `ITER_NUM` of stages

//////////////////////////////////////////////////////////////////////////////
// Constant Declarations (calculated on start)
//////////////////////////////////////////////////////////////////////////////
reg [MULT_WIDTH-1:0] MAG_SCALE;                    ///< Magnitude Scalar
reg [ANGLE_WIDTH-1:0] ANGLE_LOOKUP [ITER_NUM-1:0]; ///< Angle lookup table

//////////////////////////////////////////////////////////////////////////////
// Signal Declarations
//////////////////////////////////////////////////////////////////////////////
reg [ITER_WIDTH-1:0] iter;      ///< Iteration counter
reg [ANGLE_WIDTH-1:0] angleReg; ///< Angle register
reg signed [IN_WIDTH:0] xReg;   ///< X coordinate working register
reg signed [IN_WIDTH-1:0] yReg; ///< Y coordinate working register
reg doneD1;

wire signed [IN_WIDTH+MULT_WIDTH:0] magCalc;
wire done;

integer i;
real magScaleCalc;

//////////////////////////////////////////////////////////////////////////////
// Main Code
//////////////////////////////////////////////////////////////////////////////

// Calculate constants
initial begin
    for (i=0; i<ITER_NUM; i=i+1) begin
        ANGLE_LOOKUP[i] = $rtoi(($atan(2.0**(-i)) * 2.0**(ANGLE_WIDTH-1) / M_PI)+0.5);
    end
    magScaleCalc = 1.0;
    for (i=0; i<ITER_NUM; i=i+1) begin
        magScaleCalc = magScaleCalc * (1.0+2.0**(-2.0*i))**(-0.5);
    end
    MAG_SCALE = $rtoi(2.0**(MULT_WIDTH) * magScaleCalc);
end

if (SCALE_MAGNITUDE) begin
    assign magCalc = xReg * MAG_SCALE;
end
else begin
    assign magCalc = 'd0;
end

// Algorithm loop
assign done = (iter == (ITER_NUM-1));
always @(posedge clk) begin
    if (rst) begin
        iter      <= ITER_NUM-1;
        doneD1    <= 1'b1;
        magnitude <= 'd0;
        outStrobe <= 1'b0;
        angle     <= 'd0;
        xReg      <= 'd0;
        yReg      <= 'd0;
        angleReg  <= 'd0;
    end
    else begin
        doneD1 <= done;
        outStrobe <= done & ~doneD1;
        if (done & ~doneD1) begin
            angle <= angleReg;
            if (SCALE_MAGNITUDE) begin
                magnitude <= magCalc >>> MULT_WIDTH;
            end
            else begin
                magnitude <= xReg;
            end
        end
        if (inStrobe) begin
            iter <= 'd0;
            case ({y[IN_WIDTH-1], x[IN_WIDTH-1]}) // y<0, x<0
                2'b00 : begin xReg <=  x; yReg <=  y; angleReg <= (0 << (ANGLE_WIDTH-2)); end // 0-90 degrees
                2'b01 : begin xReg <=  y; yReg <= -x; angleReg <= (1 << (ANGLE_WIDTH-2)); end // 90-180 degrees
                2'b11 : begin xReg <= -x; yReg <= -y; angleReg <= (2 << (ANGLE_WIDTH-2)); end // 180-270 degrees
                2'b10 : begin xReg <= -y; yReg <=  x; angleReg <= (3 << (ANGLE_WIDTH-2)); end // 270-360 degrees
            endcase
        end
        else if (!done) begin
            iter <= iter + 2'd1;
            if (yReg[IN_WIDTH-1]) begin // yReg < 0
                xReg <= xReg - (yReg >>> iter);
                yReg <= yReg + (xReg >>> iter);
                angleReg <= angleReg - ANGLE_LOOKUP[iter];
            end
            else begin
                xReg <= xReg + (yReg >>> iter);
                yReg <= yReg - (xReg >>> iter);
                angleReg <= angleReg + ANGLE_LOOKUP[iter];
            end
        end
    end
end

endmodule
