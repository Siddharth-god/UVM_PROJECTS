// ENV CONFIG
class ram_env_config extends uvm_object;
    `uvm_object_utils(ram_env_config)
    `NEW_OBJ

    // ENV CONFIG DOES NOT HAVE => uvm_active_passive_enum & vif (only in low lvl cfg)

    int has_rd_agent = 1; // Values by default
    int has_wr_agent = 1; 
    int has_sb = 1; 
    int no_of_duts = 1;
    int has_functional_cov = 0;

    ram_wr_agent_config wr_cfg[]; // every low lvl agent will have it's own config.
    ram_rd_agent_config rd_cfg[];

endclass 