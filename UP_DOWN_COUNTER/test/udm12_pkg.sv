package udm12_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "../tb/udm12_global_cfg.sv" // holds vif so must be created before drv or mon

    `include "../in_agent_top/udm12_xtn.sv"
    `include "../in_agent_top/udm12_drv.sv"
    `include "../in_agent_top/udm12_mon.sv"
    `include "../in_agent_top/udm12_seqr.sv"
    `include "../in_agent_top/udm12_seq.sv"
    `include "../in_agent_top/udm12_agent.sv"

    `include "../out_agent_top/udm12_mon.sv"
    `include "../out_agent_top/udm12_agent.sv"

    `include "../tb/udm12_sb.sv"
    `include "../tb/udm12_vseqr.sv"
    `include "../tb/udm12_env.sv"

    `include "../tb/udm12_vseq.sv"
    `include "../test/udm_test.sv"

endpackage