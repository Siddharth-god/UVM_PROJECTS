// Sequencer -----------------------------------------------------------------------------------------
class seqr extends uvm_sequencer #(xtn);

    `uvm_component_utils(seqr)

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction 

endclass 