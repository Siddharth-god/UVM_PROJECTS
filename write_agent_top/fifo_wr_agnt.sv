
// Agent -------------------------------------------------------------------------------
class wr_agent extends uvm_agent;
    `uvm_component_utils(wr_agent)
    `NEW_COMP

    wr_seqr wr_seqr_h;
    wr_monitor wr_monitor_h;
    wr_driver wr_driver_h;


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        wr_monitor_h = wr_monitor::type_id::create("wr_monitor_h",this);
        //if(is_active == UVM_ACTIVE) begin 
            wr_driver_h = wr_driver::type_id::create("wr_driver_h",this);
            wr_seqr_h = wr_seqr::type_id::create("wr_seqr_h",this);
        //end
    endfunction    

    function void connect_phase(uvm_phase phase);
        wr_driver_h.seq_item_port.connect(wr_seqr_h.seq_item_export);
    endfunction  

endclass 
