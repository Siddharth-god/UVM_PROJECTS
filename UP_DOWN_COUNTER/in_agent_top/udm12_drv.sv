
// Driver -----------------------------------------------------------------------------------------
class driver extends uvm_driver #(xtn);

    `uvm_component_utils(driver)

    virtual udm12_if vif;   
    global_config g_cfg;

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if(!uvm_config_db #(global_config)::get(this,"","global_config",g_cfg))
            `uvm_fatal("DRIVER","cannot get() vif from TEST")
    endfunction 

    function void connect_phase(uvm_phase phase);
        vif = g_cfg.vif;
    endfunction

    task run_phase(uvm_phase phase);

        // Now drive transactions forever
        forever begin
            seq_item_port.get_next_item(req);

            @(vif.drv_cb);
            vif.drv_cb.rstn <= req.rstn;
            vif.drv_cb.data_in <= req.data_in;
            vif.drv_cb.mode <= req.mode;
            vif.drv_cb.load <= req.load;

            seq_item_port.item_done();
        end

    endtask
endclass 
