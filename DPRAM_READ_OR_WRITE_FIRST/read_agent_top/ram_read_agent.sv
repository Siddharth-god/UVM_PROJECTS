//------------------------------------------------------- READ_AGT -------------------------------------------------

class ram_rd_agt extends uvm_agent;
    `uvm_component_utils(ram_rd_agt)
    `NEW_COMP

    ram_rd_drv ram_rd_drvh;
    ram_rd_seqr ram_rd_seqrh;
    ram_rd_mon ram_rd_monh; 

    ram_rd_agent_config rd_cfg;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(ram_rd_agent_config)::get(this,"","ram_rd_agent_config",rd_cfg))
            `uvm_fatal(get_type_name(),"Failed to get rd_cfg from ENV")

        ram_rd_monh = ram_rd_mon::type_id::create("ram_rd_monh",this);

        if(rd_cfg.is_active == UVM_ACTIVE) begin 
            ram_rd_drvh = ram_rd_drv::type_id::create("rd_drvh",this);
            ram_rd_seqrh = ram_rd_seqr::type_id::create("ram_rd_seqrh",this);
        end
    endfunction 

    function void connect_phase(uvm_phase phase);
        ram_rd_drvh.seq_item_port.connect(ram_rd_seqrh.seq_item_export);
    endfunction

endclass 
