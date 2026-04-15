
// // TOP------------------------------------------------
// module ram_top;

//     import ram_pkg::*;
//     import uvm_pkg::*;

//     bit clk = 0;
//     always #5 clk = ~clk; 

//     int RAM_MODE = 0; // By default read mode 

//     dpram_if #(.WIDTH(WIDTH),.ADDR_BUS(ADDR_BUS)) IF(clk);

//     ram #(.WIDTH(WIDTH),
//         .DEPTH(DEPTH),
//         .ADDR_BUS(ADDR_BUS),
//         //.MODE(1) // Write first mode 
//         .MODE(0) // Read first mode
//         )DUT(
//             .clk(clk),
//             .rst(IF.rst),
//             .din(IF.din),
//             .dout(IF.dout),
//             .wr_adr(IF.wr_adr),
//             .rd_adr(IF.rd_adr),
//             .we(IF.we),
//             .re(IF.re)
//         );
    
//     initial begin 
//         uvm_config_db #(virtual dpram_if #(.WIDTH(WIDTH),.ADDR_BUS(ADDR_BUS)))::set(null,"*","vif[0]",IF);
//         uvm_config_db #(int)::set(null,"*","ram_mode",RAM_MODE); 
//         run_test();
//     end
// endmodule 
module ram_top;
    import ram_pkg::*;
    import uvm_pkg::*;

    // 1. Check if a Macro was passed from the command line. 
    // If not, default to 1 (Write-First).
    `ifndef RAM_MODE_VAL
        `define RAM_MODE_VAL 1
    `endif

    localparam RUNTIME_MODE = `RAM_MODE_VAL;

    bit clk = 0;
    always #5 clk = ~clk; 

    dpram_if #(.WIDTH(WIDTH),.ADDR_BUS(ADDR_BUS)) IF(clk);

    // 2. Pass the RUNTIME_MODE to the DUT
    ram #(.WIDTH(WIDTH),
          .DEPTH(DEPTH),
          .ADDR_BUS(ADDR_BUS),
          .MODE(RUNTIME_MODE) 
         ) DUT (
            .clk(clk),
            .rst(IF.rst),
            .din(IF.din),
            .dout(IF.dout),
            .wr_adr(IF.wr_adr),
            .rd_adr(IF.rd_adr),
            .we(IF.we),
            .re(IF.re)
        );
    
    initial begin 
        // 3. Put the value into config_db for the Scoreboard
        uvm_config_db #(int)::set(null, "*", "ram_mode", RUNTIME_MODE);
        
        uvm_config_db #(virtual dpram_if #(.WIDTH(WIDTH),.ADDR_BUS(ADDR_BUS)))::set(null,"*","vif[0]",IF);
        run_test();
    end
endmodule