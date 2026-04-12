
// Driver -------------------------------------------------------------------------------
// If Both driver sets reset in interface rstn is x, design breaks --- good question and topic to add on linkdin

class wr_driver extends uvm_driver #(xtn);
    `uvm_component_utils(wr_driver)
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

        // We usually do not use driver print because it makes reading output log harder that it needs to be. 

            @(vif.wr_drv_cb) begin 
                vif.wr_drv_cb.rstn <= req.rstn;
                vif.wr_drv_cb.data_in <= req.data_in;
                vif.wr_drv_cb.write <= req.write;
            end

            seq_item_port.item_done();
        end
    endtask

endclass 