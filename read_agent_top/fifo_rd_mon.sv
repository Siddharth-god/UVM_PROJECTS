
class rd_monitor extends uvm_monitor;
    `uvm_component_utils(rd_monitor)
    `NEW_COMP

    virtual fifo_if #(WIDTH) vif;
    uvm_analysis_port #(xtn) rd_mon_port;
    g_config g_cfg;


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        rd_mon_port = new("rd_mon_port",this);

        if(!uvm_config_db #(g_config)::get(this,"","g_config",g_cfg))
            `uvm_fatal(get_full_name(),"Cannot get() config from TEST")
    endfunction 

    // connect config vif to vif 
    function void connect_phase(uvm_phase phase);
        vif = g_cfg.vif;
    endfunction    

    task run_phase(uvm_phase phase);
        xtn xtnh;
        
        forever begin 
            @(vif.rd_mon_cb)
            
            if(vif.rd_mon_cb.read) begin 
                xtnh = xtn::type_id::create("xtnh");
                xtnh.rstn = vif.rd_mon_cb.rstn;
                xtnh.read = vif.rd_mon_cb.read;
                xtnh.data_out = vif.rd_mon_cb.data_out;
                xtnh.full = vif.rd_mon_cb.full;
                xtnh.empty = vif.rd_mon_cb.empty;

                `uvm_info(get_type_name(),"Sampling transaction", UVM_LOW)
                xtnh.print();

                rd_mon_port.write(xtnh);
            end
        end
    endtask

endclass