
module fifo #(
    WIDTH, 
    ADDR
)(
    input  logic clk,
    input  logic rstn,
    input  logic read,
    input  logic write,
    input  logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out,
    output logic full,
    output logic empty
);
    localparam DEPTH = 2**ADDR;

    // for sva check for data
    logic [WIDTH-1:0] q_data;

    logic [WIDTH-1:0] fifo_mem [DEPTH-1:0];
    logic [ADDR-1:0]  rdp;
    logic [ADDR-1:0]  wrp;
    logic [ADDR : 0]  count;

    always_ff @(posedge clk) begin
        if(!rstn) begin
            rdp <= 0;
            wrp <= 0;
            count <= 0;
            data_out <= 0;

            for(int i=0; i<DEPTH; i++) begin
                fifo_mem[i] <= 0;
            end
        end
        else begin
            if(read && !empty) begin
                data_out <= fifo_mem[rdp];
                rdp <= rdp + 1;
                count--;
            end

            if(write && !full) begin
                fifo_mem[wrp] <= data_in;
                wrp <= wrp + 1;
                count++;
            end
        end
    end

    assign empty = (count == 0);
    assign full = (count == DEPTH);

endmodule
