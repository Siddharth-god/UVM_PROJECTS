
// Test -------------------------------------------------------------------------------
class fifo_test extends uvm_test;
    `uvm_component_utils(fifo_test)
    `NEW_COMP

    env envh;
    g_config g_cfg;
    vseq vseqh;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        g_cfg = g_config::type_id::create("g_cfg");
        vseqh = vseq::type_id::create("vseqh");

        if(!uvm_config_db #(virtual fifo_if #(WIDTH))::get(this,"","fifo_if",g_cfg.vif))
            `uvm_fatal(get_full_name(),"Cannot get() vif from TOP")

        // set config to all low levels
        uvm_config_db #(g_config)::set(this,"*","g_config",g_cfg);

        envh = env::type_id::create("envh",this);
    endfunction     

    task run_phase(uvm_phase phase);
            phase.raise_objection(this);
            vseqh.start(envh.vseqrh);
            phase.drop_objection(this);
    endtask 

endclass 
