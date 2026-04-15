
// Test -----------------------------------------------------------------------------------------
class udm_test extends uvm_test;

    `uvm_component_utils(udm_test)

    env envh;
    global_config g_cfg;
    vseq vseqh;

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        g_cfg = global_config::type_id::create("g_cfg");
        vseqh = vseq::type_id::create("vseqh");

        if(!uvm_config_db #(virtual udm12_if)::get( this, "", "udm12_if", g_cfg.vif))
            `uvm_fatal(get_full_name(),"Cannot get() global config from ---TOP---")

        uvm_config_db #(global_config)::set( this, "*", "global_config", g_cfg);

        envh = env::type_id::create("envh",this);
    endfunction 

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        vseqh.start(envh.vseqrh);
        phase.drop_objection(this);
    endtask 
endclass 