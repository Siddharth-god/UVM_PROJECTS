
// Interface --------------------------------------------------------------------------------

interface fifo_if #(WIDTH)(input bit clk);
    logic rstn;
    logic read;
    logic write;
    logic [WIDTH-1:0] data_in;
    logic [WIDTH-1:0] data_out;
    logic full;
    logic empty;

    clocking wr_drv_cb@(posedge clk); // --> Input skew is #1 means sample #1 after posedge, and drive after #1 after posedge.
        output  rstn;
        output  write;
        output  data_in;
    endclocking 

    clocking wr_mon_cb@(posedge clk); // --> By default the skew is : input skew #1 and output is #0
        input  rstn;
        input  read;
        input  write;
        input  data_in;   
        input  full;
        input  empty;  
    endclocking 

    clocking rd_drv_cb@(posedge clk); // --> But sample actually happens after edge means we get the DUT output one cycle later.
        input  rstn; // why input ? --> Because reset can only be driven by one driver, another driver only observes it and uses it.  
        output read;  
    endclocking

    clocking rd_mon_cb@(posedge clk); // --> So, when we add #0 to any signal that signal will be outputted at posedge, and sampling happens in observed region no race condition occurs 
        default input #0; // why 1step will misalign ? --> Because it will make the monitor sample after posedge -> leading one extra cycle for sampling.
        input rstn;
        input read;
        input data_out; // making #0 Can cause race in complex designs -- (as per industry #1step is correct which is by default present)
        input full;
        input empty;    
    endclocking

    modport WR_DRV(clocking wr_drv_cb);
    modport WR_MON(clocking wr_mon_cb);
    modport RD_DRV(clocking rd_drv_cb);
    modport RD_MON(clocking rd_mon_cb);
    
endinterface