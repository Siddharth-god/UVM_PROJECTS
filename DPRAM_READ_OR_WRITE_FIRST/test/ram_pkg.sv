package ram_pkg;
	import uvm_pkg::*;
	`include "uvm_macros.svh"

	parameter WIDTH = 8;
    parameter DEPTH = 16;
    parameter ADDR_BUS = 4;

//------------------------------DEFAULT MACROS--------------------------------
    //****NEW COMPONENT****//
    `define NEW_COMP    \
        function new(string name ="", uvm_component parent);    \
            super.new(name,parent);    \
        endfunction

    //****NEW OBJECT****//
    `define NEW_OBJ    \
        function new(string name ="");    \
            super.new(name);    \
        endfunction
//------------------------------------------------------------------------------
// declare all classes

	// Transaction 
	`include "../write_agent_top/ram_write_xtn.sv"
	`include "../read_agent_top/ram_read_xtn.sv"
	
	// Config
	`include "../write_agent_top/ram_write_agent_config.sv"
	`include "../read_agent_top/ram_read_agent_config.sv"
	`include "../tb/ram_env_config.sv"

	// write agent
	`include "../write_agent_top/ram_write_driver.sv"
	`include "../write_agent_top/ram_write_monitor.sv"
	`include "../write_agent_top/ram_write_seqr.sv"
	`include "../write_agent_top/ram_write_seqs.sv"
	`include "../write_agent_top/ram_write_agent.sv"
	`include "../write_agent_top/ram_write_agent_top.sv"

	// read agent 
	`include "../read_agent_top/ram_read_monitor.sv"
	`include "../read_agent_top/ram_read_seqr.sv"
	`include "../read_agent_top/ram_read_seqs.sv"
	`include "../read_agent_top/ram_read_driver.sv"
	`include "../read_agent_top/ram_read_agent.sv"
	`include "../read_agent_top/ram_read_agent_top.sv"

// `include "ram_virtual_sequencer.sv"

// `include "ram_virtual_seqs.sv"

	`include "../tb/ram_sb.sv"
	`include "../tb/ram_env.sv"

	`include "../test/ram_test.sv"

endpackage