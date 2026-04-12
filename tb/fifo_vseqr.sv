
// Virtual seqr -------------------------------------------------------------------------------

class vseqr extends uvm_sequencer #(uvm_sequence_item);
    `uvm_component_utils(vseqr)
    `NEW_COMP

    rd_seqr rseqr;
    wr_seqr wseqr;
endclass