//------------------------------------------------------- WRITE_AGT -------------------------------------------------
class ram_wr_agt extends uvm_agent;
    `uvm_component_utils(ram_wr_agt)
    `NEW_COMP

    ram_wr_drv ram_wr_drvh;
    ram_wr_seqr ram_wr_seqrh;
    ram_wr_mon ram_wr_monh; 

    ram_wr_agent_config wr_cfg; 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        ram_wr_monh = ram_wr_mon::type_id::create("ram_wr_monh",this);

         if(!uvm_config_db #(ram_wr_agent_config)::get(this,"","ram_wr_agent_config",wr_cfg))
            `uvm_fatal(get_type_name(),"Failed to get wr_cfg from ENV")

        if(wr_cfg.is_active == UVM_ACTIVE) begin 
            ram_wr_drvh = ram_wr_drv::type_id::create("ram_wr_drvh",this);
            ram_wr_seqrh = ram_wr_seqr::type_id::create("ram_wr_seqrh",this);
        end
    endfunction 

    function void connect_phase(uvm_phase phase);
        ram_wr_drvh.seq_item_port.connect(ram_wr_seqrh.seq_item_export);
    endfunction

endclass 