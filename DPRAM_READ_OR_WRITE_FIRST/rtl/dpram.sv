module ram #(
    parameter WIDTH = 8,
    parameter DEPTH = 16,
    parameter ADDR_BUS = 4,

    // Behavior selection (future use)
    // Default to write first
    parameter MODE = 1   // 0 = READ_FIRST, 1 = WRITE_FIRST 
)(
    input clk,
    input rst,

    // Write port
    input we,
    input [ADDR_BUS-1:0] wr_adr,
    input [WIDTH-1:0] din,

    // Read port
    input re,
    input [ADDR_BUS-1:0] rd_adr,
    output reg [WIDTH-1:0] dout
);

localparam READ_FIRST  = 0;
localparam WRITE_FIRST = 1;

reg [WIDTH-1:0] mem [0:DEPTH-1];
integer i;

always @(posedge clk) begin
    if (rst) begin
        dout <= 0;
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] <= 0;   // simulation friendly
    end 
    else begin

        // -------------------------
        // SAME ADDRESS COLLISION
        // -------------------------
        if (we && re && (wr_adr == rd_adr)) begin
            if (MODE == WRITE_FIRST)
                dout <= din;           // future behavior
            else
                dout <= mem[rd_adr];   // current behavior (READ_FIRST)

            mem[wr_adr] <= din;
        end

        // -------------------------
        // NORMAL OPERATIONS
        // -------------------------
        else begin
            if (we)
                mem[wr_adr] <= din;

            if (re)
                dout <= mem[rd_adr];
        end
    end
end

endmodule