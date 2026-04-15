class out_agent extends uvm_agent;

    `uvm_component_utils(out_agent)

    out_monitor monh;

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);
        monh = out_monitor::type_id::create("monh",this);
        
    endfunction 


endclass 