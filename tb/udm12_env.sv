
// Env -----------------------------------------------------------------------------------------
class env extends uvm_env;

    `uvm_component_utils(env)

    in_agent in_agnth;
    out_agent out_agnth;
    sb sb_h;
    vseqr vseqrh;

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        vseqrh = vseqr::type_id::create("vseqrh",this);
        in_agnth = in_agent::type_id::create("in_agnth",this);
        out_agnth = out_agent::type_id::create("out_agnth",this);
        sb_h = sb::type_id::create("sb_h",this);
    endfunction 

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        vseqrh.seqrh = in_agnth.seqrh;
        // connect monitor analysis port with fifo tlm port
        in_agnth.monh.monitor_port.connect(sb_h.fifo_driver_mon_port.analysis_export);
        out_agnth.monh.out_monitor_port.connect(sb_h.fifo_sampler_mon_port.analysis_export);
    endfunction 
endclass 