
// Virtual sequence -----------------------------------------------------------------------------------
class vseq extends uvm_sequence #(uvm_sequence_item);

    `uvm_object_utils(vseq)

    function new(string name = "vseq");
        super.new(name);
    endfunction

    vseqr vseqrh;

    seq_rstn seq_rstn_h;
    seq_load seq_load_h;
    seq_md1 seq_md1_h;
    seq_md0 seq_md0_h;

    task body();

        if(!$cast(vseqrh,m_sequencer))
            `uvm_fatal(get_type_name(),"Failed to cast");

        seq_rstn_h = seq_rstn::type_id::create("seq_rstn_h");
        seq_load_h = seq_load::type_id::create("seq_load_h");
        seq_md1_h = seq_md1::type_id::create("seq_md1_h");
        seq_md0_h = seq_md0::type_id::create("seq_md0_h");

        fork 
            seq_rstn_h.start(vseqrh.seqrh); // grab - to make sure rstn alwaysg gets exacuted first. 
            seq_load_h.start(vseqrh.seqrh); // lock - to give exclusive access to this sequence
            seq_md1_h.start(vseqrh.seqrh);  // grab - 3rd priority
            seq_md0_h.start(vseqrh.seqrh);  // grab - 2nd priority
        join
    endtask 

endclass 