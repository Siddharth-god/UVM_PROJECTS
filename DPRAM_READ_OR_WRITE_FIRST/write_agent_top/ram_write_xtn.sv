// WRITE XTN 
class ram_wr_xtn extends uvm_sequence_item;
    `uvm_object_utils(ram_wr_xtn)
    `NEW_OBJ

    rand bit rst; 
	rand bit we;
	rand bit [ADDR_BUS-1:0] wr_adr;
	rand bit [WIDTH-1:0] din;

    function void do_print(uvm_printer printer);
        printer.print_field("rst",rst,1,UVM_DEC);
        printer.print_field("we",we,1,UVM_DEC);
        printer.print_field("wr_adr",wr_adr,4,UVM_DEC);
        printer.print_field("din",din,8,UVM_DEC);
    endfunction 
endclass 