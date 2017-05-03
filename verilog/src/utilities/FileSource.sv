module FileSource #(
    parameter FILE_NAME = "out.log",
    parameter OUT_WIDTH  = 8,
    parameter OUT_NUM    = 8
)
(
    input  logic clk, ///< System clock
    input  logic rst, ///< Reset, active high and synchronous
    input  logic en,  ///< Enable. Write data to file while high
    output logic signed [OUT_WIDTH-1:0] dataOut [OUT_NUM] ///< Signed data from file
);

logic rstD1;
integer fileHandle;
integer temp;

initial begin
    rstD1 = 1'b0;
    fileHandle = $fopen(FILE_NAME, "r");
end

always @(posedge clk) begin
    if (rst && !rstD1)  begin
        $fclose(fileHandle);
        fileHandle = $fopen(FILE_NAME, "r");
    end
    else if (en && (fileHandle != 0)) begin
        temp = $fscanf(fileHandle, "  %d", dataOut[0]);
        for (int i=1; i<OUT_NUM; i++) begin
            temp = $fscanf(fileHandle, " , %d", dataOut[i]);
        end
    end
    rstD1 = rst;
end

endmodule
