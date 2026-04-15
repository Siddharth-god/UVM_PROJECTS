// WRITE DRV 
class ram_wr_drv extends uvm_driver #(ram_wr_xtn);
    `uvm_component_utils(ram_wr_drv)
    `NEW_COMP

    virtual dpram_if #(.WIDTH(WIDTH),.ADDR_BUS(ADDR_BUS)) wvif;
    ram_wr_agent_config wr_cfg;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(ram_wr_agent_config)::get(this,"","ram_wr_agent_config",wr_cfg))
            `uvm_fatal(get_type_name(),"Failed to get wr_cfg in [WR_DRV] from ENV")

    endfunction 

    function void connect_phase(uvm_phase phase);
        wvif = wr_cfg.wvif;
    endfunction

    task run_phase(uvm_phase phase);
        forever begin 
            seq_item_port.get_next_item(req);
            //send_to_dut(req);
            @(wvif.wr_drv_cb) begin 
                wvif.wr_drv_cb.rst <= req.rst; 
                wvif.wr_drv_cb.we <= req.we;
                wvif.wr_drv_cb.wr_adr <= req.wr_adr;
                wvif.wr_drv_cb.din <= req.din;
            end 
            seq_item_port.item_done(); 
        end
    endtask

    // task send_to_dut(ram_wr_xtn xtnh);
        
    // endtask

endclass 