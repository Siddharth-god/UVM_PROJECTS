//------------------------------------------------------- WRITE_AGT_TOP -------------------------------------------------
class ram_wr_agt_top extends uvm_agent;
    `uvm_component_utils(ram_wr_agt_top)
    `NEW_COMP

    ram_wr_agt ram_wr_agth; 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ram_wr_agth = ram_wr_agt::type_id::create("ram_wr_agth",this);
    endfunction 


endclass 