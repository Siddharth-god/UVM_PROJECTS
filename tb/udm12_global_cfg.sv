// Config -----------------------------------------------------------------------------------------
class global_config extends uvm_object;
    `uvm_object_utils(global_config)

    virtual udm12_if vif;
    uvm_active_passive_enum is_active;

    static int inputs_sent_to_dut;
    static int outputs_sampled_from_dut;


    function new(string name = "global_config");
        super.new(name);
    endfunction
endclass 
