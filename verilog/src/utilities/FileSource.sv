/**
# FileSource

Reads a csv file into an array of signed integers. 

*/

module FileSource #(
    parameter FILE_NAME = "out.log", ///< Name of csv file to read
    parameter OUT_WIDTH  = 8,        ///< Bit width of an item in dataOut
    parameter OUT_NUM    = 8,        ///< Number of items in dataOut
    parameter CYCLE      = 1         ///< 1 to cycle through data, 0 to output X after reaching EOF
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
        if (CYCLE && $feof(fileHandle)) temp = $rewind(fileHandle);
        temp = $fscanf(fileHandle, "  %d", dataOut[0]);
        for (int i=1; i<OUT_NUM; i++) begin
            temp = $fscanf(fileHandle, " , %d ", dataOut[i]);
        end
    end
    rstD1 = rst;
end

endmodule
