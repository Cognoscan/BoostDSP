/**

# FileSink

Writes an array of signed integers to a file.

*/

module FileSink #(
    parameter FILE_NAME = "out.log", ///< Name of file to write to
    parameter IN_WIDTH  = 8,         ///< Bit width of an item in dataIn
    parameter IN_NUM    = 8          ///< Number of items in dataIn
)
(
    input logic clk,    ///< System clock
    input logic rst,    ///< Reset, active high and synchronous
    input logic en,     ///< Enable. Write data to file while high
    input logic closed, ///< Set high to close file. MUST use only at end of simulation
    input logic signed [IN_WIDTH-1:0] dataIn [IN_NUM] ///< Signed data to write to file
);

logic rstD1;
integer fileHandle;

initial begin
    rstD1 = 1'b0;
    fileHandle = $fopen(FILE_NAME, "w");
end

always @(posedge closed) $fclose(fileHandle);

always @(posedge clk) begin
    if (rst && !rstD1)  begin
        $fclose(fileHandle);
        fileHandle = $fopen(FILE_NAME, "w");
    end
    else if (en && (fileHandle != 0)) begin
        $fwrite(fileHandle, "%d", dataIn[0]);
        for (int i=1; i<IN_NUM; i++) begin
            $fwrite(fileHandle, ",%d", dataIn[i]);
        end
        $fwrite(fileHandle, "\n");
    end
    rstD1 = rst;
end

endmodule
