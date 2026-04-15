class ram_wr_seq extends uvm_sequence #(ram_wr_xtn);
    `uvm_object_utils(ram_wr_seq)
    `NEW_OBJ

endclass 

// ----------------------------- RESET SEQ ------------------------------
class seq_rst extends ram_wr_seq;
    `uvm_object_utils(seq_rst)
    `NEW_OBJ

    task body();
        $display("\n------------------------------------ Reset sequence started ------------------------------------\n\n");
        repeat(2) begin 
            req = ram_wr_xtn::type_id::create("req");
            start_item(req); 
            assert(req.randomize() with {
                rst == 1;
                we == 0; 
                wr_adr == 0; 
                din == 0; 
            });
            finish_item(req); 
        end
    endtask 
endclass 


// ----------------------------- SAME ADDR WRITE FIRST MODE CHECK ------------------------------
class same_addr_we_seq extends ram_wr_seq;
    `uvm_object_utils(same_addr_we_seq)
    `NEW_OBJ

    task body();
        $display("\n------------------------------------ Single addr write sequence started ------------------------------------\n\n");
        repeat(5) begin 
            req = ram_wr_xtn::type_id::create("req");
            start_item(req); 
            assert(req.randomize() with {
                we == 1;
                rst == 0;
                wr_adr == 12;
                din inside {[0:20]};
            });
            finish_item(req); 
        end
    endtask 
endclass 


// ----------------------------- BURST WRITE SEQ ------------------------------
class seq_wr_burst extends ram_wr_seq;
    `uvm_object_utils(seq_wr_burst)
    `NEW_OBJ

    task body();
        $display("\n------------------------------------ Burst write sequence started ------------------------------------\n\n");
        repeat(17) begin 
            req = ram_wr_xtn::type_id::create("req");
            start_item(req); 
            assert(req.randomize() with {
                rst == 0;
                we == 1;
                din inside {[0:20]};
            });
            finish_item(req); 
        end
    endtask 
endclass 