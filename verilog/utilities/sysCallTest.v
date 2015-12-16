/**

# sysCallTest #

Tests System Call capability of the compiler. Many compilers don't support all 
standard math system calls listed in the Verilog spec, and may complain 
depending on whether they are in a parameter, localparam, or initial statement. 
Use this module to see what your compiler supports.


*/


module sysCallTest
(
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
    output reg [7:0] clog2
);

parameter PARAM_LN    = $ln   ( 1234 );
parameter PARAM_LOG10 = $log10( 1234 );
parameter PARAM_EXP   = $exp  ( 1234 );
parameter PARAM_SQRT  = $sqrt ( 1234 );
parameter PARAM_POW   = $pow  ( 1234 );
parameter PARAM_FLOOR = $floor( 1234 );
parameter PARAM_CEIL  = $ceil ( 1234 );
parameter PARAM_SIN   = $sin  ( 1234 );
parameter PARAM_COS   = $cos  ( 1234 );
parameter PARAM_TAN   = $tan  ( 1234 );
parameter PARAM_ASIN  = $asin ( 1234 );
parameter PARAM_ACOS  = $acos ( 1234 );
parameter PARAM_ATAN  = $atan ( 1234 );
parameter PARAM_ATAN2 = $atan2( 1234 );
parameter PARAM_HYPOT = $hypot( 1234 );
parameter PARAM_SINH  = $sinh ( 1234 );
parameter PARAM_COSH  = $cosh ( 1234 );
parameter PARAM_TANH  = $tanh ( 1234 );
parameter PARAM_ASINH = $asinh( 1234 );
parameter PARAM_ACOSH = $acosh( 1234 );
parameter PARAM_ATANH = $atanh( 1234 );
parameter PARAM_CLOG2 = $clog2( 1234 );

localparam LOCAL_PARAM_LN    = $ln   ( 1234 );
localparam LOCAL_PARAM_LOG10 = $log10( 1234 );
localparam LOCAL_PARAM_EXP   = $exp  ( 1234 );
localparam LOCAL_PARAM_SQRT  = $sqrt ( 1234 );
localparam LOCAL_PARAM_POW   = $pow  ( 1234 );
localparam LOCAL_PARAM_FLOOR = $floor( 1234 );
localparam LOCAL_PARAM_CEIL  = $ceil ( 1234 );
localparam LOCAL_PARAM_SIN   = $sin  ( 1234 );
localparam LOCAL_PARAM_COS   = $cos  ( 1234 );
localparam LOCAL_PARAM_TAN   = $tan  ( 1234 );
localparam LOCAL_PARAM_ASIN  = $asin ( 1234 );
localparam LOCAL_PARAM_ACOS  = $acos ( 1234 );
localparam LOCAL_PARAM_ATAN  = $atan ( 1234 );
localparam LOCAL_PARAM_ATAN2 = $atan2( 1234 );
localparam LOCAL_PARAM_HYPOT = $hypot( 1234 );
localparam LOCAL_PARAM_SINH  = $sinh ( 1234 );
localparam LOCAL_PARAM_COSH  = $cosh ( 1234 );
localparam LOCAL_PARAM_TANH  = $tanh ( 1234 );
localparam LOCAL_PARAM_ASINH = $asinh( 1234 );
localparam LOCAL_PARAM_ACOSH = $acosh( 1234 );
localparam LOCAL_PARAM_ATANH = $atanh( 1234 );
localparam LOCAL_PARAM_CLOG2 = $clog2( 1234 );

initial begin
    ln    = $ln   ( 1234 );
    log10 = $log10( 1234 );
    exp   = $exp  ( 1234 );
    sqrt  = $sqrt ( 1234 );
    pow   = $pow  ( 1234 );
    floor = $floor( 1234 );
    ceil  = $ceil ( 1234 );
    sin   = $sin  ( 1234 );
    cos   = $cos  ( 1234 );
    tan   = $tan  ( 1234 );
    asin  = $asin ( 1234 );
    acos  = $acos ( 1234 );
    atan  = $atan ( 1234 );
    atan2 = $atan2( 1234 );
    hypot = $hypot( 1234 );
    sinh  = $sinh ( 1234 );
    cosh  = $cosh ( 1234 );
    tanh  = $tanh ( 1234 );
    asinh = $asinh( 1234 );
    acosh = $acosh( 1234 );
    atanh = $atanh( 1234 );
    clog2 = $clog2( 1234 );
end

endmodule

/*
ln
log10
exp
sqrt
pow
floor
ceil
sin
cos
tan
asin
acos
atan
atan2
hypot
sinh
cosh
tanh
asinh
acosh
atanh
clog2
*/
