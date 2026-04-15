// Interface we write with TB pov not DUT

interface udm12_if(input bit clk); 

    logic [3:0] data_in;
    logic rstn;
    logic mode;
    logic load;
    logic [3:0] data_out;

    // Clocking block for DRIVER (drives inputs)
    clocking drv_cb @(posedge clk);
        default input #1 output #1;
        output data_in;
        output rstn;
        output mode;
        output load;
    endclocking

    // Clocking block for MONITOR (samples signals) -- monitor usually sees all signals for debugging purpose
    clocking mon_cb @(posedge clk);
        default input #1 output #1;
        input data_in;
        input rstn;
        input mode;
        input load;
        input data_out;
    endclocking

    // Modports referencing clocking blocks
    modport DRV (clocking drv_cb);
    modport MON (clocking mon_cb);
endinterface : udm12_if
