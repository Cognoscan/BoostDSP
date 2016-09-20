/**
# CordicRectToPolar_tb - Tests CordicRectToPolar #

Only tests with full amplitude x & y. Smaller amplitudes will yield larger angle 
& magnitude errors. It is assumed that an implementation that satisfies at full 
amplitude will perform the same algorithm at smaller amplitudes.

Test parameters let one set desired criteria for passing.

*/


module CordicRectToPolar_tb ();

//////////////////////////////////////////////////////////////////////////////
// UUT Parameters
//////////////////////////////////////////////////////////////////////////////
parameter IN_WIDTH        = 16; ///< Input coordinate pair width
parameter ANGLE_WIDTH     = 16; ///< Output angle register width
parameter SCALE_MAGNITUDE = 0;  ///< Set to 1 to scale magnitude to true value
parameter MULT_WIDTH      = 16; ///< Number of bits to use for magnitude scaling word, if SCALE_MAGNITUDE is 1

//////////////////////////////////////////////////////////////////////////////
// UUT Signal Declarations
//////////////////////////////////////////////////////////////////////////////
reg                          clk;       ///< System clock
reg                          rst;       ///< Reset, active high and synchronous
reg                          inStrobe;  ///< Input data strobe
reg signed [IN_WIDTH-1:0]    x;         ///< X coordinate
reg signed [IN_WIDTH-1:0]    y;         ///< Y coordinate

wire        [ANGLE_WIDTH-1:0] angle;     ///< Angle
wire signed [IN_WIDTH:0]      magnitude; ///< Magnitude
wire                          outStrobe; ///< Output data strobe

//////////////////////////////////////////////////////////////////////////////
// Test Parameter Declarations
//////////////////////////////////////////////////////////////////////////////

parameter ITER_NUM    = (IN_WIDTH > (ANGLE_WIDTH-1)) ? (ANGLE_WIDTH-1) : IN_WIDTH;
parameter M_PI        = $acos(-1.0);

// Goals
parameter TEST_ANGLES = 2048;
parameter MAX_ANGLE_ERR_AVG         = 3.0;
parameter MAX_ANGLE_ERR_STD_DEV     = 3.0;
parameter MAX_MAGNITUDE_ERR_AVG     = 3.0;
parameter MAX_MAGNITUDE_ERR_STD_DEV = 3.0;


//////////////////////////////////////////////////////////////////////////////
// Test Signal Declarations
//////////////////////////////////////////////////////////////////////////////

reg signed [IN_WIDTH:0] magSamples [TEST_ANGLES-1:0];
reg signed [ANGLE_WIDTH-1:0] angSamples [TEST_ANGLES-1:0];

real angleErrAvg;
real angleErrStdDev;
real magnitudeErrAvg;
real magnitudeErrStdDev;
real realX;
real realY;
real realAngle;
real realMagnitude;

real MAG_SCALAR;

integer i;
integer seed;
integer pass;

//////////////////////////////////////////////////////////////////////////////
// Test Code
//////////////////////////////////////////////////////////////////////////////

function real abs (
    input real val
);
begin
    abs = (val < 0) ? -val : val;
end
endfunction

always #1 clk = ~clk;

initial begin
    // Initialize variables
    pass = 1;
    clk = 1'b0;
    rst = 1'b1;
    inStrobe = 1'b0;
    x = 'd0;
    y = 'd0;
    MAG_SCALAR = 1.0;
    seed = 345;
    for (i=0; i<ITER_NUM; i=i+1) begin
        MAG_SCALAR = MAG_SCALAR * (1.0 + 2.0**(-2.0*i))**(-0.5);
    end
    angleErrAvg        = 0.0;
    angleErrStdDev     = 0.0;
    magnitudeErrAvg    = 0.0;
    magnitudeErrStdDev = 0.0;
    
    // Reset module
    @(posedge clk) rst = 1'b1;
    @(posedge clk) rst = 1'b1;
    @(posedge clk) rst = 1'b0;
    @(posedge clk) rst = 1'b0;

    // Gather data
    realMagnitude = 2.0**(IN_WIDTH-1)-1;
    for (i=0; i<TEST_ANGLES; i=i+1) begin
        realAngle = $dist_uniform(seed, 0, (1<<ANGLE_WIDTH)-1) * 2.0 * M_PI / (1<<ANGLE_WIDTH);
        realX = realMagnitude * $cos(realAngle);
        realY = realMagnitude * $sin(realAngle);
        x = $rtoi(realX+0.5);
        y = $rtoi(realY+0.5);
        @(posedge clk) inStrobe = 1'b1;
        @(posedge clk) inStrobe = 1'b0;
        wait(outStrobe);
        if (SCALE_MAGNITUDE) begin
            magSamples[i] = $itor(magnitude) - realMagnitude;
        end
        else begin
            magSamples[i] = $itor(magnitude) - realMagnitude / MAG_SCALAR;
        end
        angSamples[i] = $itor(angle)     - (realAngle*2.0**(ANGLE_WIDTH-1)/M_PI);
        magnitudeErrAvg = magnitudeErrAvg + magSamples[i];
        angleErrAvg     = angleErrAvg     + angSamples[i];
        wait(~outStrobe);
    end

    // Calculate mean & standard deviation
    angleErrAvg = angleErrAvg / TEST_ANGLES;
    magnitudeErrAvg = magnitudeErrAvg / TEST_ANGLES;
    for (i=0; i<TEST_ANGLES; i=i+1) begin
        angleErrStdDev = angleErrStdDev + (angSamples[i] - angleErrAvg)**(2.0);
        magnitudeErrStdDev = magnitudeErrStdDev + (magSamples[i] - magnitudeErrAvg)**(2.0);
    end
    angleErrStdDev = $sqrt(angleErrStdDev / (TEST_ANGLES-1));
    magnitudeErrStdDev = $sqrt(magnitudeErrStdDev / (TEST_ANGLES-1));

    $display("Number of angle bits: %d", ANGLE_WIDTH);
    $display("Number of input bits: %d", IN_WIDTH);
    $display("Magnitude Average Error: %f", magnitudeErrAvg);
    $display("Magnitude Standard Deviation of Error: %f", magnitudeErrStdDev);
    $display("Angle Average Error: %f", angleErrAvg);
    $display("Angle Standard Deviation of Error: %f", angleErrStdDev);
    if (abs(magnitudeErrAvg) > MAX_MAGNITUDE_ERR_AVG) begin
        pass = 0;
        $display("FAIL: Magnitude average error is too high");
    end
    if (magnitudeErrStdDev > MAX_MAGNITUDE_ERR_STD_DEV) begin
        pass = 0;
        $display("FAIL: Magnitude standard deviation is too high");
    end
    if (abs(angleErrAvg) > MAX_ANGLE_ERR_AVG) begin
        pass = 0;
        $display("FAIL: angle average error is too high");
    end
    if (angleErrStdDev > MAX_ANGLE_ERR_STD_DEV) begin
        pass = 0;
        $display("FAIL: angle standard deviation is too high");
    end
    if (pass) begin
        $display("PASS");
    end
    $stop;
end

//////////////////////////////////////////////////////////////////////////////
// UUT 
//////////////////////////////////////////////////////////////////////////////
CordicRectToPolar #(
    .IN_WIDTH       (IN_WIDTH       ), ///< Input coordinate pair width
    .ANGLE_WIDTH    (ANGLE_WIDTH    ), ///< Output angle register width
    .SCALE_MAGNITUDE(SCALE_MAGNITUDE), ///< Set to 1 to scale magnitude to true value
    .MULT_WIDTH     (MULT_WIDTH     )  ///< Number of bits to use for magnitude scaling word, if SCALE_MAGNITUDE is 1
)
uut (
    .clk(clk),             ///< System clock
    .rst(rst),             ///< Reset, active high and synchronous
    .inStrobe(inStrobe),   ///< Input data strobe
    .x(x),                 ///< [IN_WIDTH-1:0] X coordinate
    .y(y),                 ///< [IN_WIDTH-1:0] Y coordinate
    .angle(angle),         ///< [ANGLE_WIDTH-1:0] Angle
    .magnitude(magnitude), ///< [IN_WIDTH:0] Magnitude
    .outStrobe(outStrobe)  ///< Output data strobe
);

endmodule
