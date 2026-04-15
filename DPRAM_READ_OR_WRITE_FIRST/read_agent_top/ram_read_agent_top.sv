//------------------------------------------------------- READ_AGT_TOP -----------------------------------------------------
class ram_rd_agt_top extends uvm_agent;
    `uvm_component_utils(ram_rd_agt_top)
    `NEW_COMP

    ram_rd_agt ram_rd_agth; 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ram_rd_agth = ram_rd_agt::type_id::create("ram_rd_agth",this);
    endfunction 

endclass 