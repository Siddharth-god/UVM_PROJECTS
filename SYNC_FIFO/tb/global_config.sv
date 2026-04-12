// Global Config -------------------------------------------------------------------------------

class g_config extends uvm_object;
    `uvm_object_utils(g_config)
    `NEW_OBJ

    virtual fifo_if #(WIDTH) vif;
    uvm_active_passive_enum is_active; 

endclass