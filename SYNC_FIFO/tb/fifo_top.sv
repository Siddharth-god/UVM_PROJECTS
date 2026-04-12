
module fifo_top;

    import uvm_pkg::*;
    import fifo_pkg::*;

    bit clk = 0;

    parameter WIDTH = 8;
    parameter ADDR  = 4;
    
    always #5 clk = ~clk;

    fifo_if #(.WIDTH(WIDTH)) IF(clk);

    fifo #(
        .WIDTH(WIDTH),
        .ADDR(ADDR)
        ) DUT(
        .clk(clk),
        .rstn(IF.rstn),
        .data_in(IF.data_in),
        .data_out(IF.data_out),
        .read(IF.read),
        .write(IF.write),
        .full(IF.full),
        .empty(IF.empty)
    );

    bind fifo fifo_assertions #(
        .WIDTH(WIDTH),
        .ADDR(ADDR)
        ) FIFO_ASSERTIONS(
        .clk(clk),
        .rstn(rstn),
        .data_in(data_in),
        .data_out(data_out),
        .read(read),
        .write(write),
        .full(full),
        .empty(empty),
        .count(DUT.count),
        .rdp(DUT.rdp),
        .wrp(DUT.wrp)
    );


    initial begin 
        uvm_config_db #(virtual fifo_if #(WIDTH))::set(null,"*","fifo_if",IF);
        run_test(); 
    end
endmodule 
//-------------------------------------------------------------END---------------------------------------------------------------
