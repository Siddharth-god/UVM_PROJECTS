class ram_rd_seq extends uvm_sequence #(ram_rd_xtn);
    `uvm_object_utils(ram_rd_seq)
    `NEW_OBJ
endclass 

// ----------------------------- SINGLE ADDR READ FIRST MODE CHECK ------------------------------
class same_addr_re_seq extends ram_rd_seq; 
    `uvm_object_utils(same_addr_re_seq)
    `NEW_OBJ

    task body(); 
        $display("\n------------------------------------ Single addr read sequence started ------------------------------------\n\n");
        repeat(5) begin 
            req = ram_rd_xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {
                re == 1;
                rd_adr == 12;
            }); 
            finish_item(req);
        end
    endtask 
endclass 


// ----------------------------- BURST READ SEQ ------------------------------
class seq_rd_burst extends ram_rd_seq;
    `uvm_object_utils(seq_rd_burst)
    `NEW_OBJ

    task body();
        $display("\n------------------------------------ Burst read sequence started ------------------------------------\n\n");
        repeat(17) begin 
            req = ram_rd_xtn::type_id::create("req");
            start_item(req); 
            assert(req.randomize() with {
                re == 1; 
            });
            finish_item(req); 
        end
    endtask 
endclass 