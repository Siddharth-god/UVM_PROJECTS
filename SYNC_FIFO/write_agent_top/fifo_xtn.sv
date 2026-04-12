
// Transaction -------------------------------------------------------------------------------

class xtn extends uvm_sequence_item;
    `uvm_object_utils(xtn)
    `NEW_OBJ

    rand bit rstn;  
    rand bit read;
    rand bit write;
    rand bit [WIDTH-1:0] data_in;
    bit [WIDTH-1:0] data_out;
    bit full;
    bit empty;

    virtual function void do_print(uvm_printer printer);
        printer.print_field("data_in",data_in,8,UVM_DEC);
        printer.print_field("write",write,1,UVM_DEC);
        printer.print_field("read",read,1,UVM_DEC);
        printer.print_field("rstn",rstn,1,UVM_DEC);
        printer.print_field("full",full,1,UVM_DEC);
        printer.print_field("empty",empty,1,UVM_DEC);
        printer.print_field("data_out",data_out,8,UVM_DEC);
    endfunction 

endclass 
