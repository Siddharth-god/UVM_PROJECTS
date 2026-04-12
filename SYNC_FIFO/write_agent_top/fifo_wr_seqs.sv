
// Sequence -------------------------------------------------------------------------------

class seq_base extends uvm_sequence #(xtn);
    `uvm_object_utils(seq_base)
    `NEW_OBJ
endclass 

// reset 
class seq_rst extends seq_base;
    `uvm_object_utils(seq_rst)
    `NEW_OBJ

    task body();
        repeat(2) begin 
            req = xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {rstn == 0;});
            finish_item(req);
        end
    endtask 
endclass 

// write only / burst write
class seq_write extends seq_base;
    `uvm_object_utils(seq_write)
    `NEW_OBJ

    task body();
        repeat(17) begin 
            req = xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {write == 1 && rstn == 1 && read == 0;});
            finish_item(req);
        end
    endtask 
endclass 

// read only / burst read 
class seq_read extends seq_base;
    `uvm_object_utils(seq_read)
    `NEW_OBJ

    task body();
        repeat(20) begin 
            req = xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {write == 0 && rstn == 1 && read == 1;});
            finish_item(req);
        end
    endtask 
endclass 

// random traffic write
class seq_random_wr extends seq_base;
    `uvm_object_utils(seq_random_wr)
    `NEW_OBJ

    task body();
        repeat(100) begin 
            req = xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {
                write dist { 1:=20, 0:=80};
                rstn == 1;
            });
            finish_item(req);
        end
    endtask 
endclass 

// random traffic read
class seq_random_rd extends seq_base;
    `uvm_object_utils(seq_random_rd)
    `NEW_OBJ

    task body();
        repeat(100) begin 
            req = xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {
                read dist { 1:=70, 0:=30};
                rstn == 1;
            });
            finish_item(req);
        end
    endtask 
endclass 
