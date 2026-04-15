//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx SB xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//------------------------------------------------------- SB -----------------------------------------------------
class ram_sb extends uvm_scoreboard;
    `uvm_component_utils(ram_sb)
    `NEW_COMP

    uvm_tlm_analysis_fifo #(ram_rd_xtn) fifo_rd; 
    uvm_tlm_analysis_fifo #(ram_wr_xtn) fifo_wr; 

    ram_wr_xtn wr_xtn; 
    ram_rd_xtn rd_xtn; 

    static int match_counter = 0; 
    static int mismatch_counter = 0; 

    int sb_mode; 

    reg [WIDTH-1:0] exp_data [int]; // Associative array for higher protection


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        fifo_rd = new("fifo_rd",this);
        fifo_wr = new("fifo_wr",this); 

        if(!uvm_config_db #(int)::get(this,"","ram_mode",sb_mode))
            `uvm_fatal(get_type_name(),"Failed to get MODE from TOP")

    endfunction 

    task run_phase(uvm_phase phase); 
        $display("!!! SCOREBOARD VERSION 2.0 RUNNING !!!");
        $display("<<<<xxxxxx SB MODE xxxxxx>>>> %0d",sb_mode);

            forever begin
                bit [WIDTH-1:0] exp_out; 
                int exist; // Will be used to compare and throw the warinig (without this comarision is hard)

                fork 
                    fifo_wr.get(wr_xtn); 
                    fifo_rd.get(rd_xtn); 
                join
                
                $display("\nData in fifo from WR MON :\n rst=%0d | we=%0d | wd_adr=%0d | din=%0d",
                    wr_xtn.rst,
                    wr_xtn.we,
                    wr_xtn.wr_adr,
                    wr_xtn.din
                );

                $display("\nData in fifo from RD MON :\n re=%0d | rd_adr=%0d | dout=%0d\n",
                        rd_xtn.re,
                        rd_xtn.rd_adr,
                        rd_xtn.dout
                    );

                if(wr_xtn.we && rd_xtn && (wr_xtn.wr_adr == rd_xtn.rd_adr)) begin : COLLISION

                    if(sb_mode == 1) begin : WRITE_FIRST_MODE
                        exp_data[wr_xtn.wr_adr] = wr_xtn.din; // Update first
                        $display("Memory_Written with Expected Data :\n[%p]",exp_data);
                        exp_out = exp_data[rd_xtn.rd_adr];   // Read after update 
                        $display("Exp out = %0d",exp_out); 
                        exist = 1;
                    end : WRITE_FIRST_MODE

                    else begin : READ_FIRST_MODE
                        if(exp_data.exists(rd_xtn.rd_adr)) begin // get exp_out only if valid address to read from
                            exp_out = exp_data[rd_xtn.rd_adr];   // Read First 
                            $display("Exp out = %0d",exp_out); 
                            exist = 1;
                        end
                        else 
                            exist = 0; 
                        exp_data[wr_xtn.wr_adr] = wr_xtn.din; // Update after read 
                        $display("Memory_Written with Expected Data :\n[%p]",exp_data);
                    end : READ_FIRST_MODE
                end : COLLISION

                else begin : NORMAL_OPERATION
                    if(wr_xtn.we) begin  
                        exp_data[wr_xtn.wr_adr] = wr_xtn.din;
                        $display("Memory_Written with Expected Data :\n[%p]",exp_data);
                    end

                    if(rd_xtn.re) begin 
                        if(exp_data.exists(rd_xtn.rd_adr)) begin // Check if addr is valid 
                            exp_out = exp_data[rd_xtn.rd_adr];
                            $display("Exp out = %0d",exp_out); 
                            exist = 1; 
                        end
                        else 
                            exist = 0; 
                    end
                end : NORMAL_OPERATION

                // Compare the output 
                if(rd_xtn.re) begin 
                    if(exist) begin 
                        if(exp_out == rd_xtn.dout) begin 
                            `uvm_info(
                                get_type_name(),
                                $sformatf("\n\nScoreboard : [Data Match Successful]\n[dout : exp_out] = [%0d:%0d]",rd_xtn.dout,exp_out),
                                UVM_LOW)
                            match_counter++; 
                            $display("\ndata match : [%0d]\n",match_counter);
                        end
                        else begin
                            `uvm_error(
                                get_type_name(),
                                $sformatf("\n\nScoreboard : [Data Mismatch]\n[dout : exp_out] = [%0d:%0d]",rd_xtn.dout,exp_out))
                            mismatch_counter++; 
                            $display("\ndata mismatch : [%0d]\n",mismatch_counter);
                        end
                    end
                    else /// THis line is the issue debug it 
                        `uvm_warning(get_type_name(),$sformatf("Read from empty addr: %0d", rd_xtn.rd_adr))
                end
            end
    endtask 
endclass 


/*
That is a perfectly logical way to think! If your RTL already has a default value for the `MODE` parameter, you don't *technically* need to pass it every time.

However, there is one major reason why we still explicitly pass it in the Makefile for **every** target: **Synchronization.**

### The "Stale Logic" Problem
If you run `make run_test_read_first` (which sets `MODE=0`), the simulator compiles the `work` library with `MODE=0`.

If you then immediately run `make run_test_burst` without specifying a mode:
1.  The Makefile sees `sv_cmp` as a dependency.
2.  It re-compiles the code using the **default** value in the Makefile (which is `MODE ?= 1`).
3.  The `work` library is overwritten with `MODE=1`.

If you *don't* have `sv_cmp` as a dependency and just run `vsim`, it will use whatever was compiled **last**. So if your last run was Read-First, your Burst test will accidentally run in Read-First mode too!



---

### Why your approach is mostly fine
Your current Makefile is actually very safe because you have `wclean` and `sv_cmp` in your targets. This means:
* **Every time** you type a `make` command, it deletes the old library and re-compiles from scratch.
* If you don't specify `MODE` for the Burst test, it uses `MODE ?= 1` from the top of your Makefile.

### The Best Practice Tip
In industry, we usually explicitly write the mode in the Makefile for every test target. This is called **"Self-Documenting Code."** When a teammate looks at your Makefile, they shouldn't have to guess what the default is. They can see:
* `run_test_write_first` $\rightarrow$ Uses `MODE=1`
* `run_test_read_first` $\rightarrow$ Uses `MODE=0`
* `run_test_burst` $\rightarrow$ Uses `MODE=0`

It prevents "Ghost Bugs" where you think you are testing one thing, but the simulator is actually using a leftover setting from a previous run.

---
*/

/*
                    $display("\n\n<<<<xxxxxx Executing [WRITE FIRST MODE] UPDATE BLOCK xxxxxx>>>>\n\n");
// 
    task run_phase(uvm_phase phase); 
        $display("!!! SCOREBOARD VERSION 2.0 RUNNING !!!");
        fork
            forever begin
                // Thread 1: Monitor Writes and update Reference Model
                fifo_wr.get(wr_xtn); 

                $display("\nData in fifo from WR MON :\n rst=%0d | we=%0d | wd_adr=%0d | din=%0d",
                    wr_xtn.rst,
                    wr_xtn.we,
                    wr_xtn.wr_adr,
                    wr_xtn.din
                );

                if(wr_xtn.we) begin 
                    #1; // This delay will help mimic read first mode. Read first - Write later. 
                    exp_data[wr_xtn.wr_adr] = wr_xtn.din;

                     $display("Memory_Written with Expected Data :\n[%p]",exp_data);
                end
            end
            forever begin
                // Thread 2: Monitor Reads and Compare
                bit [WIDTH-1:0] exp_out; 
                fifo_rd.get(rd_xtn); 

                $display("\nData in fifo from RD MON :\n re=%0d | rd_adr=%0d | dout=%0d\n",
                        rd_xtn.re,
                        rd_xtn.rd_adr,
                        rd_xtn.dout
                    );
                    
                if(rd_xtn.re) begin // Begin only if valid read 
                    if(exp_data.exists(rd_xtn.rd_adr)) begin // Compare only if valid address to read from
                        exp_out = exp_data[rd_xtn.rd_adr]; // Getting expected form the local array
                        $display("Exp out = %0d",exp_out);

                        if(exp_out == rd_xtn.dout) begin 
                            `uvm_info(
                                get_type_name(),
                                $sformatf("\n\nScoreboard : [Data Match Successful]\n[dout : exp_out] = [%0d:%0d]",rd_xtn.dout,exp_out),
                                UVM_LOW)
                            match_counter++; 
                            $display("\ndata match : [%0d]\n",match_counter);
                        end
                        else begin
                            `uvm_error(
                                get_type_name(),
                                $sformatf("\n\nScoreboard : [Data Mismatch]\n[dout : exp_out] = [%0d:%0d]",rd_xtn.dout,exp_out))
                            mismatch_counter++; 
                            $display("\ndata mismatch : [%0d]\n",mismatch_counter);
                        end
                    end
                    else 
                        `uvm_warning(get_type_name(),$sformatf("Read from empty addr: %0d", rd_xtn.rd_adr))
                end
            end
        join
    endtask 
*/
