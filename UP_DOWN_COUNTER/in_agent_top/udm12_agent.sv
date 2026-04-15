
// Agent -----------------------------------------------------------------------------------------
class in_agent extends uvm_agent;

    `uvm_component_utils(in_agent)

    seqr seqrh;
    driver drvh;
    in_monitor monh;
    global_config g_cfg;

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        seqrh = seqr::type_id::create("seqrh",this);
        drvh = driver::type_id::create("drvh",this);
        monh = in_monitor::type_id::create("monh",this);
        
    endfunction 

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        drvh.seq_item_port.connect(seqrh.seq_item_export);
    endfunction

endclass 