// Package 
package fifo_pkg;
    parameter WIDTH = 8;
    parameter ADDR  = 4;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

//------------------------------------DEFAULT MACROS--------------------------------------
    `define NEW_COMP	\
        function new(string name = "", uvm_component parent);	\
            super.new(name,parent);	\
        endfunction

    //******** NEW Object
    `define NEW_OBJ	\
        function new(string name = "");	\
            super.new(name);	\
        endfunction
//------------------------------------------------------------------------------------------

    `include "../tb/global_config.sv"

    `include "../write_agent_top/fifo_xtn.sv"
    `include "../write_agent_top/fifo_wr_drv.sv"
    `include "../write_agent_top/fifo_wr_mon.sv"
    `include "../write_agent_top/fifo_wr_seqr.sv"
    `include "../write_agent_top/fifo_wr_seqs.sv"
    `include "../write_agent_top/fifo_wr_agnt.sv"

    `include "../read_agent_top/fifo_rd_drv.sv"
    `include "../read_agent_top/fifo_rd_mon.sv"
    `include "../read_agent_top/fifo_rd_seqr.sv"
    `include "../read_agent_top/fifo_rd_agnt.sv"
  
    `include "../tb/fifo_sb.sv"
    `include "../tb/fifo_vseqr.sv"
    `include "../tb/fifo_env.sv"
    `include "../tb/fifo_vseqs.sv"

    `include "../test/fifo_test.sv"
endpackage





//------------------------------------DEFAULT MACROS--------------------------------------
`define NEW_COMP	\
	function new(string name = "", uvm_component parent);	\
		super.new(name,parent);	\
	endfunction

//******** NEW Object
`define NEW_OBJ	\
	function new(string name = "");	\
		super.new(name);	\
	endfunction
//------------------------------------------------------------------------------------------