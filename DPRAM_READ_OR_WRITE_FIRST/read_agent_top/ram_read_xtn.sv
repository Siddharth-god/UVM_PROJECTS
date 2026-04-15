// READ XTN
class ram_rd_xtn extends uvm_sequence_item;
    `uvm_object_utils(ram_rd_xtn)
    `NEW_OBJ

	rand bit re;
	rand bit [ADDR_BUS-1:0] rd_adr;
	bit [WIDTH-1:0] dout;

    function void do_print(uvm_printer printer);
        printer.print_field("re",re,1,UVM_DEC);
        printer.print_field("rd_adr",rd_adr,4,UVM_DEC);
        printer.print_field("dout",dout,8,UVM_DEC);
    endfunction 
endclass 