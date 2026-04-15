// READ MON 
class ram_rd_mon extends uvm_monitor;
    `uvm_component_utils(ram_rd_mon)
    `NEW_COMP

    ram_rd_agent_config rd_cfg; 
    virtual dpram_if #(.WIDTH(WIDTH),.ADDR_BUS(ADDR_BUS)) rvif;
    ram_rd_xtn xtnh; 
    uvm_analysis_port #(ram_rd_xtn) rd_mon_port; 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        rd_mon_port = new("rd_mon_port",this); 
        xtnh = ram_rd_xtn::type_id::create("xtnh"); 

        if(!uvm_config_db #(ram_rd_agent_config)::get(this,"","ram_rd_agent_config",rd_cfg))
            `uvm_fatal(get_type_name(),"Failed to get rd_cfg from ENV")
    endfunction 

    function void connect_phase(uvm_phase phase);
        rvif = rd_cfg.rvif; 
    endfunction 

    task run_phase(uvm_phase phase); 
        forever begin 
            @(rvif.rd_mon_cb) begin 
                xtnh.re = rvif.rd_mon_cb.re;
                xtnh.rd_adr = rvif.rd_mon_cb.rd_adr; 
                xtnh.dout = rvif.rd_mon_cb.dout; 
            end
            rd_mon_port.write(xtnh);
            `uvm_info(get_type_name(),$sformatf("\nSAMPLING READ TRANSACTIONS : \n%s",xtnh.sprint()),UVM_LOW)
        end
    endtask 

endclass 