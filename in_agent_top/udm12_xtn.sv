
// Transaction -----------------------------------------------------------------------------------------
class xtn extends uvm_sequence_item;

    `uvm_object_utils(xtn)

    rand bit [3:0] data_in;
    rand bit mode, load;
    rand bit rstn;
    bit [3:0] data_out;

    function new(string name = "xtn");
        super.new(name);
    endfunction 

    constraint valid_vals{
        foreach(data_in[i])
            data_in inside {[0:11]};
        mode dist { 1:=5, 0:=5};
        load dist { 1:=5, 0:=5};
        rstn dist { 1:=8, 0:=2};
    }

    // do copy and compare not needed here - using basic comparision in sb

    virtual function void do_print(uvm_printer printer);
        super.do_print(printer);
        printer.print_field("data_in",  data_in,    4, UVM_DEC);
        printer.print_field("rstn",     rstn,       1, UVM_DEC);
        printer.print_field("mode",     mode,       1, UVM_DEC);
        printer.print_field("load",     load,       1, UVM_DEC);
        printer.print_field("data_out", data_out,   4, UVM_DEC);
    endfunction

endclass 