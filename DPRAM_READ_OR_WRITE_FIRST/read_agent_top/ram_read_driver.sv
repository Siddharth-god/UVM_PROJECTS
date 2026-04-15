// READ DRV
class ram_rd_drv extends uvm_driver #(ram_rd_xtn);
    `uvm_component_utils(ram_rd_drv)
    `NEW_COMP

    virtual dpram_if #(.WIDTH(WIDTH),.ADDR_BUS(ADDR_BUS)) rvif;
    ram_rd_agent_config rd_cfg;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(ram_rd_agent_config)::get(this,"","ram_rd_agent_config",rd_cfg))
            `uvm_fatal(get_type_name(),"Failed to get rd_cfg in [RD_DRV] from ENV")

    endfunction 

    function void connect_phase(uvm_phase phase);
        rvif = rd_cfg.rvif;
    endfunction

    task run_phase(uvm_phase phase);
        forever begin 
           seq_item_port.get_next_item(req);

            @(rvif.rd_drv_cb) begin 
                rvif.rd_drv_cb.re <= req.re; 
                rvif.rd_drv_cb.rd_adr <= req.rd_adr; 
            end 

           seq_item_port.item_done(); 
        end
    endtask 

    // function void send_to_dut(ram_rd_xtn xtnh);
        
    // endfunction 
endclass 
