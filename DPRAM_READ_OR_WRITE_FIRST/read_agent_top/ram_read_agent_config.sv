// READ CONFIG
class ram_rd_agent_config extends uvm_object;
    `uvm_object_utils(ram_rd_agent_config)
    `NEW_OBJ

    virtual dpram_if #(.WIDTH(WIDTH),.ADDR_BUS(ADDR_BUS)) rvif; 
    uvm_active_passive_enum is_active = UVM_ACTIVE;
    // static int drv_data_xtn_count = 0;
    // static int mon_data_xtn_count = 0; 
endclass 