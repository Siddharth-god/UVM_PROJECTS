// WRITE CONFIG
class ram_wr_agent_config extends uvm_object;
    `uvm_object_utils(ram_wr_agent_config)
    `NEW_OBJ

    virtual dpram_if #(.WIDTH(WIDTH),.ADDR_BUS(ADDR_BUS)) wvif; 
    uvm_active_passive_enum is_active = UVM_ACTIVE;
endclass 