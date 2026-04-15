
class out_monitor extends uvm_monitor;

    `uvm_component_utils(out_monitor)

    virtual udm12_if vif;
    global_config g_cfg;
   
    uvm_analysis_port #(xtn) out_monitor_port;

    function new(string name, uvm_component parent);
        super.new(name,parent);
        out_monitor_port = new("out_monitor_port",this);
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

            //if(vif.mon_cb.rstn) // We are using rstn sequence -to observe rstn behaviour we cannot use this condition as this will skip rstn = 0
            begin
                sample_dut = xtn::type_id::create("sample_dut");
                sample_dut.data_out = vif.mon_cb.data_out;

                out_monitor_port.write(sample_dut);

                g_cfg.outputs_sampled_from_dut ++;
                $display("Report: Number of Sampled outputs = %0d",g_cfg.outputs_sampled_from_dut);
            end
        end
    endtask 

endclass 