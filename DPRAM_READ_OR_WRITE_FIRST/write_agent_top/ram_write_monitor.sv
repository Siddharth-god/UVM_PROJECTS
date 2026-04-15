class ram_wr_mon extends uvm_monitor;
    `uvm_component_utils(ram_wr_mon)
    `NEW_COMP

    ram_wr_agent_config wr_cfg; 
    virtual dpram_if #(.WIDTH(WIDTH), .ADDR_BUS(ADDR_BUS)) wvif; 
    ram_wr_xtn xtnh; 

    uvm_analysis_port #(ram_wr_xtn) wr_mon_port; 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        wr_mon_port = new("wr_mon_port",this); 
        xtnh = ram_wr_xtn::type_id::create("xtnh"); 

        if(!uvm_config_db #(ram_wr_agent_config)::get(this,"","ram_wr_agent_config",wr_cfg))
            `uvm_fatal(get_type_name(),"Failed to get wr_cfg from ENV")

    endfunction 

    function void connect_phase(uvm_phase phase); 
        wvif = wr_cfg.wvif; 
    endfunction 

    task run_phase(uvm_phase phase);
        forever begin 
            @(wvif.wr_mon_cb) begin 
                xtnh.rst = wvif.wr_mon_cb.rst; 
                xtnh.we =  wvif.wr_mon_cb.we; 
                xtnh.wr_adr = wvif.wr_mon_cb.wr_adr; 
                xtnh.din = wvif.wr_mon_cb.din; 
            end
            wr_mon_port.write(xtnh);
            `uvm_info(get_type_name(),$sformatf("\nSAMPLING WRITE TRANSACTIONS :\n%s",xtnh.sprint()),UVM_LOW)
        end
    endtask 
endclass 