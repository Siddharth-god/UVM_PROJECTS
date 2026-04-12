// rd driver
class rd_driver extends uvm_driver #(xtn); // read driver cannot control reset else logic breaks
    `uvm_component_utils(rd_driver)
    `NEW_COMP

    virtual fifo_if #(WIDTH) vif;
    g_config g_cfg;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(g_config)::get(this,"","g_config",g_cfg))
            `uvm_fatal(get_full_name(),"Cannot get() config from TEST")
    endfunction     

    // connect config vif to vif 
    function void connect_phase(uvm_phase phase);
        vif = g_cfg.vif;
    endfunction

    task run_phase(uvm_phase phase);

        forever begin
            seq_item_port.get_next_item(req);

            @(vif.rd_drv_cb)
                vif.rd_drv_cb.read <= req.read;

            seq_item_port.item_done();
        end
    endtask

endclass 
