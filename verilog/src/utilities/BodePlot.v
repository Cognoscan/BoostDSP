module BodePlot
#(
    parameter EXCITE_WIDTH    = 16,
    parameter RESPONSE_WIDTH  = 16,
    parameter SAMPLE_RATE     = 25e6,
    parameter LOW_FREQ        = 100,
    parameter HIGH_FREQ       = 20e3,
    parameter NUM_SAMPLES     = 1024
(
    input  clk,
    input  rst,
    input  en,
    input  start,
    input  [RESPONSE_WIDTH-1:0] sinResponse,
    input  [RESPONSE_WIDTH-1:0] cosResponse,
    output reg  signed [EXCITE_WIDTH-1:0] sinExcitation,
    output reg  signed [EXCITE_WIDTH-1:0] cosExcitation,
    output reg  resultStrobe;
    output real freq,
    output real mag,
    output real phase
);

integer i;
integer j;

initial begin
    sinExcitation = 1'b0;
    cosExcitation = 1'b0;
    resultStrobe = 1'b0;
    freq = 0.0;
    mag = 0.0;
    phase = 0.0;
end

always @(posedge start) begin
    for (i=0; i < NUM_SAMPLES; i++) begin
        freq = (HIGH_FREQ-LOW_FREQ)*$itor(i)/NUM_SAMPLES + LOW_FREQ;
        for (j=0; j<NUM_SETTLE_CLKS; j=j+1) begin
            @posedge(en);
            sinExcitation = $rtoi( (2**(EXCITE_WIDTH-1)-1)*$sin(freq*2*PI*$itor(j)/SAMPLE_RATE));
            cosExcitation = $rtoi( (2**(EXCITE_WIDTH-1)-1)*$cos(freq*2*PI*$itor(j)/SAMPLE_RATE));
            @(negedge clk);
        end
        resultStrobe = 1'b1;
        
        
    end
end

endmodule
