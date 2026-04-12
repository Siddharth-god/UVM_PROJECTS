
class rd_agent extends uvm_agent;
    `uvm_component_utils(rd_agent)
    `NEW_COMP

    rd_seqr rd_seqr_h;
    rd_monitor rd_monitor_h;
    rd_driver rd_driver_h;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        rd_monitor_h = rd_monitor::type_id::create("rd_monitor_h",this);
        //if(is_active == UVM_ACTIVE) begin 
            rd_driver_h = rd_driver::type_id::create("rd_driver_h",this);
            rd_seqr_h = rd_seqr::type_id::create("rd_seqr_h",this);
        //end
    endfunction   

    function void connect_phase(uvm_phase phase);
        rd_driver_h.seq_item_port.connect(rd_seqr_h.seq_item_export);
    endfunction   

endclass 
