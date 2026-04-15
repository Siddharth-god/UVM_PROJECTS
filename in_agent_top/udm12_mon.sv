
// Monitor -----------------------------------------------------------------------------------------
class in_monitor extends uvm_monitor;

    `uvm_component_utils(in_monitor)

    virtual udm12_if vif;
    global_config g_cfg;
   
    uvm_analysis_port #(xtn) monitor_port;

    function new(string name, uvm_component parent);
        super.new(name,parent);
        monitor_port = new("monitor_port",this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if(!uvm_config_db #(global_config)::get(this,"","global_config",g_cfg))
            `uvm_fatal("MONITOR","cannot get() vif from TEST")
    endfunction 


    function void connect_phase(uvm_phase phase);
        vif = g_cfg.vif;
    endfunction

    task run_phase(uvm_phase phase);

        xtn sample_dut;

        forever begin 
            
            @(vif.mon_cb)  

                //if(vif.mon_cb.rstn) // only sample on off rstn. To check rstn behaviour we cannot use this.
                begin
                    sample_dut = xtn::type_id::create("sample_dut");

                    sample_dut.data_in = vif.mon_cb.data_in;
                    sample_dut.mode = vif.mon_cb.mode;
                    sample_dut.load = vif.mon_cb.load;
                    sample_dut.rstn = vif.mon_cb.rstn;

                    monitor_port.write(sample_dut);

                    g_cfg.inputs_sent_to_dut ++;
                    $display("Report: Number of driven inputs = %0d",g_cfg.inputs_sent_to_dut);
                end
        end
    endtask 
endclass 
