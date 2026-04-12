
// Virtual seq -------------------------------------------------------------------------------

class vseq extends uvm_sequence #(uvm_sequence_item);
    `uvm_object_utils(vseq)
    `NEW_OBJ

    // declare handles for sequences -- handles cannot be declared inside body else error.
    seq_write seq_wrh; 
    seq_read seq_rdh;
    seq_random_wr seq_rdm_wr_h;
    seq_random_rd seq_rdm_rd_h;
    seq_rst seq_rsth;

    vseqr vseqrh;

    task body();

        // casting to assign parent seqr handle with child seqr handle. 
        if(!$cast(vseqrh, m_sequencer))
            `uvm_fatal(get_full_name(), "Casting failed in Vsequence");

        // create the objects for sequences
        seq_rsth = seq_rst::type_id::create("seq_rsth");
        seq_rdh = seq_read::type_id::create("seq_rdh");
        seq_wrh = seq_write::type_id::create("seq_wrh");

        // for random ------
        seq_rdm_wr_h = seq_random_wr::type_id::create("seq_rdm_wr_h");
        seq_rdm_rd_h = seq_random_rd::type_id::create("seq_rdm_rd_h");


    // start sequence on physical sequencer

    // Reset mode ------------------------------------

        $display("\n-----------------------------RESET MODE ON-----------------------------\n\n");
        seq_rsth.start(vseqrh.wseqr);


    // Burst mode ------------------------------------

        $display("\n-----------------------------BURST MODE ON-----------------------------\n\n");
        seq_wrh.start(vseqrh.wseqr);
        seq_rdh.start(vseqrh.rseqr);


    // Simultaneous read and write -------------------

        $display("\n-----------------------------SIMULTANEOUS RW MODE ON-----------------------------\n\n");
        fork
            seq_rdh.start(vseqrh.rseqr);
            seq_wrh.start(vseqrh.wseqr);
        join

    // Random traffic ----------------------------

        $display("\n-----------------------------RANDOM TRAFFIC MODE ON-----------------------------\n\n");
        fork
            seq_rdm_wr_h.start(vseqrh.wseqr);
            seq_rdm_rd_h.start(vseqrh.rseqr);
        join
    endtask
endclass    