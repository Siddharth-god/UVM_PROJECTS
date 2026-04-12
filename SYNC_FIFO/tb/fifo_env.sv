
// Environment -------------------------------------------------------------------------------
class env extends uvm_env;
    `uvm_component_utils(env)
    `NEW_COMP

    rd_agent rd_agent_h;
    wr_agent wr_agent_h;
    sb sbh;
    vseqr vseqrh;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sbh = sb::type_id::create("sbh",this);
        rd_agent_h = rd_agent::type_id::create("rd_agent_h",this);
        wr_agent_h = wr_agent::type_id::create("wr_agent_h",this);
        vseqrh = vseqr::type_id::create("vseqrh",this);
    endfunction  

    function void connect_phase(uvm_phase phase);
        // connect vseqr seqr's and agent seqr's
        vseqrh.rseqr = rd_agent_h.rd_seqr_h;
        vseqrh.wseqr = wr_agent_h.wr_seqr_h; 

        // connect analysis port and analysis fifo
        rd_agent_h.rd_monitor_h.rd_mon_port.connect(sbh.fifo_rd.analysis_export);
        wr_agent_h.wr_monitor_h.wr_mon_port.connect(sbh.fifo_wr.analysis_export);
    endfunction   

endclass 