/**

# sysCallTest #

Tests System Call capability of the compiler. Many compilers don't support all 
standard math system calls listed in the Verilog spec, and may complain 
depending on whether they are in a parameter, localparam, or initial statement. 
Use this module to see what your compiler supports.

Currently, known unsupported sections are commented out. Vivado 2015.4 complains 
about not supporting system function calls, but appears to be partially lying, 
as it produces correct output for $clog2 in parameters, and $sin and $clog2 in 
initialization.

The aim of this project is to be universally compatible, so please provide 
feedback after experimenting with an unlisted program.

## Tested Programs ##

- Modelsim 10.2c
- Xilinx Vivado 2015.4
- Xilinx ISE 14.7

## Recommendations ##

- rtoi, ln, log10, exp, sqrt, pow, floor, ceil, sin, tan, asin, acos, atan, 
  hypot, sinh, tanh, clog2 are all OK for ISE and Modelsim
- For Vivado, the only "known good" function is $clog2, although $sin can be 
  used in initialization routines. Somehow, Vivado is worse than ISE in this 
  area...
- Avoid cos, atan2, cosh, asinh, acosh, and atanh
- Never use localparam for values requiring system calls - it won't work in 
  Xilinx tools.
- If performing more complex math, wrap it inside a function and set it in an 
  "initial" statement block
- As always, never use any system calls in normal logic.

*/


module sysCallTest
(
    input [9:0] angle,
    output reg [7:0] ln,
    output reg [7:0] log10,
    output reg [7:0] exp,
    output reg [7:0] sqrt,
    output reg [7:0] pow,
    output reg [7:0] floor,
    output reg [7:0] ceil,
    output reg [7:0] sin,
    output reg [7:0] cos,
    output reg [7:0] tan,
    output reg [7:0] asin,
    output reg [7:0] acos,
    output reg [7:0] atan,
    output reg [7:0] atan2,
    output reg [7:0] hypot,
    output reg [7:0] sinh,
    output reg [7:0] cosh,
    output reg [7:0] tanh,
    output reg [7:0] asinh,
    output reg [7:0] acosh,
    output reg [7:0] atanh,
    output reg [7:0] clog2,
    output reg [15:0] sineOut
);

parameter PARAM_LN    = 255 * $ln   ( 1234 );
parameter PARAM_LOG10 = 255 * $log10( 1234 );
parameter PARAM_EXP   = 255 * $exp  ( 1234 );
parameter PARAM_SQRT  = 255 * $sqrt ( 1234 );
parameter PARAM_POW   = 255 * $pow  ( 1234 , 3 );
parameter PARAM_FLOOR = 255 * $floor( 1234 );
parameter PARAM_CEIL  = 255 * $ceil ( 1234 );
parameter PARAM_SIN   = 255 * $sin  ( 1234 );
// parameter PARAM_COS   = 255 * $cos  ( 1234 ); // Unsupported: Modelsim
parameter PARAM_TAN   = 255 * $tan  ( 1234 );
parameter PARAM_ASIN  = 255 * $asin ( 1234 );
parameter PARAM_ACOS  = 255 * $acos ( 1234 );
parameter PARAM_ATAN  = 255 * $atan ( 1234 );
// parameter PARAM_ATAN2 = 255 * $atan2( 1234 , 3); // Unsupported: Modelsim
parameter PARAM_HYPOT = 255 * $hypot( 1234 , 3);
parameter PARAM_SINH  = 255 * $sinh ( 1234 );
// parameter PARAM_COSH  = 255 * $cosh ( 1234 ); // Unsupported: Modelsim
parameter PARAM_TANH  = 255 * $tanh ( 1234 );
// parameter PARAM_ASINH = 255 * $asinh( 1234 ); // Unsupported: Modelsim
// parameter PARAM_ACOSH = 255 * $acosh( 1234 ); // Unsupported: Modelsim
// parameter PARAM_ATANH = 255 * $atanh( 1234 ); // Unsupported: Modelsim
parameter PARAM_CLOG2 = 255 * $clog2( 1234 );

// localparam LOCAL_PARAM_LN    = $ln   ( 1234 );     // Unsupported: ISE, Vivado
// localparam LOCAL_PARAM_LOG10 = $log10( 1234 );     // Unsupported: ISE, Vivado
// localparam LOCAL_PARAM_EXP   = $exp  ( 1234 );     // Unsupported: ISE, Vivado
// localparam LOCAL_PARAM_SQRT  = $sqrt ( 1234 );     // Unsupported: ISE, Vivado
// localparam LOCAL_PARAM_POW   = $pow  ( 1234 , 3 ); // Unsupported: ISE, Vivado
// localparam LOCAL_PARAM_FLOOR = $floor( 1234 );     // Unsupported: ISE, Vivado
// localparam LOCAL_PARAM_CEIL  = $ceil ( 1234 );     // Unsupported: ISE, Vivado
// localparam LOCAL_PARAM_SIN   = $sin  ( 1234 );     // Unsupported: ISE, Vivado
// localparam LOCAL_PARAM_COS   = $cos  ( 1234 );     // Unsupported: ISE, Vivado, Modelsim
// localparam LOCAL_PARAM_TAN   = $tan  ( 1234 );     // Unsupported: ISE, Vivado
// localparam LOCAL_PARAM_ASIN  = $asin ( 1234 );     // Unsupported: ISE, Vivado
// localparam LOCAL_PARAM_ACOS  = $acos ( 1234 );     // Unsupported: ISE, Vivado
// localparam LOCAL_PARAM_ATAN  = $atan ( 1234 );     // Unsupported: ISE, Vivado
// localparam LOCAL_PARAM_ATAN2 = $atan2( 1234 , 3);  // Unsupported: ISE, Vivado, Modelsim
// localparam LOCAL_PARAM_HYPOT = $hypot( 1234 , 3);  // Unsupported: ISE, Vivado
// localparam LOCAL_PARAM_SINH  = $sinh ( 1234 );     // Unsupported: ISE, Vivado
// localparam LOCAL_PARAM_COSH  = $cosh ( 1234 );     // Unsupported: ISE, Vivado, Modelsim
// localparam LOCAL_PARAM_TANH  = $tanh ( 1234 );     // Unsupported: ISE, Vivado
// localparam LOCAL_PARAM_ASINH = $asinh( 1234 );     // Unsupported: ISE, Vivado, Modelsim
// localparam LOCAL_PARAM_ACOSH = $acosh( 1234 );     // Unsupported: ISE, Vivado, Modelsim
// localparam LOCAL_PARAM_ATANH = $atanh( 1234 );     // Unsupported: ISE, Vivado, Modelsim
// localparam LOCAL_PARAM_CLOG2 = $clog2( 1234 );     // Unsupported: ISE, Vivado

initial begin
    ln    = 255 * $ln   ( 1234 );
    log10 = 255 * $log10( 1234 );
    exp   = 255 * $exp  ( 1234 );
    sqrt  = 255 * $sqrt ( 1234 );
    pow   = 255 * $pow  ( 1234 , 3 );
    floor = 255 * $floor( 1234 );
    ceil  = 255 * $ceil ( 1234 );
    sin   = 255 * $sin  ( 1234 );
    cos   = 255 * $cos  ( 1234 );
    tan   = 255 * $tan  ( 1234 );
    asin  = 255 * $asin ( 1234 );
    acos  = 255 * $acos ( 1234 );
    atan  = 255 * $atan ( 1234 );
    atan2 = 255 * $atan2( 1234 , 3);
    hypot = 255 * $hypot( 1234 , 3 );
    sinh  = 255 * $sinh ( 1234 );
    cosh  = 255 * $cosh ( 1234 );
    tanh  = 255 * $tanh ( 1234 );
    // asinh = 255 * $asinh( 1234 ); // Unsupported: Modelsim
    // acosh = 255 * $acosh( 1234 ); // Unsupported: Modelsim
    // atanh = 255 * $atanh( 1234 ); // Unsupported: Modelsim
    clog2 = 255 * $clog2( 1234 );
end


reg [15:0] sinTable [1023:0];
localparam TABLE_LEN = 2**10;
localparam OUT_WIDTH = 16;

integer i;

initial begin
    for(i=0; i<TABLE_LEN; i=i+1) begin
        sinTable[i] = $rtoi($floor($sin((i+0.5)*3.14159/(TABLE_LEN*2))*(2**(OUT_WIDTH-1)-1)+0.5));
    end
end

always @(*) begin
    sineOut = sinTable[angle];
end

endmodule

