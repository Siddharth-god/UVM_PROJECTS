
//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ENV xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//------------------------------------------------------- ENV -----------------------------------------------------
class ram_env extends uvm_env;
    `uvm_component_utils(ram_env)
    `NEW_COMP

    ram_rd_agt_top ram_rd_agt_toph[];
    ram_wr_agt_top ram_wr_agt_toph[];
    ram_sb ram_sbh[]; // Each agent top will have different sb for comparision.  

    ram_env_config env_cfg;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Get the config 
        if(!uvm_config_db #(ram_env_config)::get(this,"","ram_env_config",env_cfg))
            `uvm_fatal(get_type_name(),"Failed to get env_cfg into ENV from TEST")


        // Create Write agents ---------------------
        if(env_cfg.has_wr_agent) begin 
            ram_wr_agt_toph = new[env_cfg.no_of_duts];

            foreach(ram_wr_agt_toph[i]) begin 
                ram_wr_agt_toph[i] = ram_wr_agt_top::type_id::create($sformatf("ram_wr_agt_toph[%0d]",i),this);
                // Till now we haven't set agent_configs which holds is active and vif to low lvl components (here we do that)
                // we use $sformatf(%0d,i) ==> While only getting ==> While setting we can directly set with [i]
                
                uvm_config_db #(ram_wr_agent_config)::set(this,"*","ram_wr_agent_config",env_cfg.wr_cfg[i]);
            end
        end


        // Create Read agents ---------------------
        if(env_cfg.has_rd_agent) begin 
            ram_rd_agt_toph = new[env_cfg.no_of_duts];

            foreach(ram_rd_agt_toph[i]) begin 
                ram_rd_agt_toph[i] = ram_rd_agt_top::type_id::create($sformatf("ram_rd_agt_toph[%0d]",i),this);
                // Till now we haven't set agent_configs which holds is active and vif to low lvl components (here we do that)

                uvm_config_db #(ram_rd_agent_config)::set(this,"*","ram_rd_agent_config",env_cfg.rd_cfg[i]);
            end
        end

        // Create Virtual Seqr ----------------------
        //...

        // Create Scoreboards -----------------------
        if(env_cfg.has_sb) begin 
            ram_sbh = new[env_cfg.no_of_duts];

            foreach(ram_sbh[i])
                ram_sbh[i] = ram_sb::type_id::create($sformatf("ram_sbh[%0d]",i),this);
        end
    endfunction 

    function void connect_phase(uvm_phase phase);

        // Connect Virtual Seqr to seqrs of agents 
        //...

        // Connect the monitor with SB
        if(env_cfg.has_sb) begin 
            foreach(ram_wr_agt_toph[i])
                ram_wr_agt_toph[i].ram_wr_agth.ram_wr_monh.wr_mon_port.connect(ram_sbh[i].fifo_wr.analysis_export);
            foreach(ram_rd_agt_toph[i])
                ram_rd_agt_toph[i].ram_rd_agth.ram_rd_monh.rd_mon_port.connect(ram_sbh[i].fifo_rd.analysis_export);
        end
    endfunction 
endclass 