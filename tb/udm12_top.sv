
// Top -----------------------------------------------------------------------------------------
module udm_top;

    import udm12_pkg::*;
    import uvm_pkg::*;


    bit clk = 0;
    int cc = 10;

    udm12_if UDM_FF(clk);
       
    udm12 DUT(
        .data_in(UDM_FF.data_in), 
        .clk(clk),
        .rstn(UDM_FF.rstn),
        .mode(UDM_FF.mode),
        .load(UDM_FF.load),
        .data_out(UDM_FF.data_out)
    );

    bind udm12 udm12_assertions UDM_ASSERTION(
                                        .data_in(data_in),
                                        .clk(clk),
                                        .rstn(rstn),
                                        .mode(mode),
                                        .load(load),
                                        .data_out(data_out)
                                    );

    always #(cc/2) clk = ~clk;

    initial begin 
        uvm_config_db #(virtual udm12_if)::set(null,"*","udm12_if",UDM_FF);
        run_test();
    end
endmodule 
