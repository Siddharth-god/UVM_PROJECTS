
// Scoreboard -------------------------------------------------------------------------------

 class sb extends uvm_scoreboard; 
    `uvm_component_utils(sb)

    xtn rd_xtn;
    xtn wr_xtn; 
    xtn ref_data[$];
    xtn pop_ref;
    int push_debugger;
    int pop_debugger;

    xtn write_cov_data; 
    xtn read_cov_data;
    static int invalid_write;
    static int invalid_read;

    uvm_tlm_analysis_fifo #(xtn) fifo_rd;
    uvm_tlm_analysis_fifo #(xtn) fifo_wr;

    // NOTE :: full is controlled by write side ==> empty is controlled by read side
    // empty during write ≠ interesting scenario --> It doesn’t verify behavior --> It’s just a state observation
    // Operation	Meaningful signals
    // write  ==>  full
    // read	  ==>  empty

    covergroup write_coverage;
        W_DATA : coverpoint write_cov_data.data_in iff (write_cov_data.write){
            bins low  = {[0:63]};
            bins mid1 = {[64:127]};
            bins mid2 = {[128:191]};
            bins high = {[192:255]};
        }
        W_RESET     : coverpoint write_cov_data.rstn;

        WR          : coverpoint write_cov_data.write { bins wr_enb_high = {1}; }
        WR_FULL     : coverpoint write_cov_data.full;
        WR_FULL_x_WR: cross WR_FULL, WR;
    endgroup

    covergroup read_coverage;
        R_DATA : coverpoint read_cov_data.data_out iff (read_cov_data.read){
            bins low  = {[0:63]};
            bins mid1 = {[64:127]};
            bins mid2 = {[128:191]};
            bins high = {[192:255]};
        }
        RD           : coverpoint read_cov_data.read { bins rd_enb_high = {1}; }
        RD_EMPTY     : coverpoint read_cov_data.empty;
        RD_EMPTY_x_RD: cross RD_EMPTY, RD;
    endgroup

    function new(string name="", uvm_component parent);
        super.new(name, parent);
        fifo_rd = new("fifo_rd", this);
        fifo_wr = new("fifo_wr", this);
        write_coverage = new();
        read_coverage  = new();
    endfunction

    function void ref_model(xtn local_wrxtn);

        if(local_wrxtn.rstn && local_wrxtn.write) begin 

            if(!local_wrxtn.full) begin 
                ref_data.push_back(local_wrxtn);
                push_debugger++;
                $display("push_debugger = %0d",push_debugger);
                $display("---------Data Pushed into queue----------|| dut_data = %0d at time=%0t | read=%0d | write=%0d | full=%0d | empty=%0d | rstn=%0d",
                        local_wrxtn.data_in, 
                        $time,
                        local_wrxtn.read,
                        local_wrxtn.write,
                        local_wrxtn.full,
                        local_wrxtn.empty,
                        local_wrxtn.rstn
                    );
            end
            else if(local_wrxtn.full) begin
                invalid_write++;
                $display("\nFIFO IS ===> FULL = %0d",local_wrxtn.full);
                $display("///////// INVALID WRITE HAPPENED //////// ==> %0d",invalid_write);
                $display("///////// INVALID ONLY CARED FOR COVERAGE - NOT FOR DATA COMPARISION////////\n");
                
            end
            else
                $display("---PUSH--- HAS NOT HAPPENED --> Maybe it is either FULL or RESET\n");
        end
    endfunction 

    function void pop_here(xtn local_rdxtn);
        if(local_rdxtn.read && local_rdxtn.rstn) begin 

            if(!local_rdxtn.empty && (ref_data.size() > 0)) begin 
                pop_ref = ref_data.pop_front();  
                pop_debugger++;
                $display("pop_debugger = %0d",pop_debugger);
                $display("---------Data Popped from queue----------|| exp_data = %0d at time=%0t | read=%0d | write=%0d | empty=%0d | full=%0d",
                        pop_ref.data_out,
                        $time, 
                        local_rdxtn.read,
                        local_rdxtn.write,
                        local_rdxtn.empty,
                        local_rdxtn.full
                    );
            end
            else if(local_rdxtn.empty) begin 
                invalid_read++;
                $display("\nFIFO IS ===> EMPTY=%0d",local_rdxtn.empty);
                $display("///////// INVALID READ HAPPENED //////// ==> %0d TIMES",invalid_read);
                $display("///////// INVALID ONLY CARED FOR COVERAGE - NOT FOR DATA COMPARISION////////\n");
            end
            else 
                $display("---POP--- HAS NOT HAPPENED --> Maybe it is either EMPTY or RESET\n");
        end
    endfunction
    
    task run_phase(uvm_phase phase);
        fork
            forever begin
                fifo_wr.get(wr_xtn);
                // DEBUG PRINT ---> NOT NEEDED IN REAL CORRECT OP 
                //$display("/////////// get write mon data /////////// data_in=%0d | rstn=%0d | write=%0d | full=%0d | empty = %0d | time=%0t",
                            //wr_xtn.data_in, wr_xtn.rstn, wr_xtn.write, wr_xtn.full, wr_xtn.empty, $time);
                ref_model(wr_xtn);
                write_cov_data = wr_xtn;
                write_coverage.sample();
            end
            forever begin
                fifo_rd.get(rd_xtn);
                //$display("/////////// get read mon data /////////// data_out=%0d | read=%0d | write=%0d | full=%0d | empty=%0d | time=%0t",
                            //rd_xtn.data_out, rd_xtn.read, rd_xtn.write, rd_xtn.full, rd_xtn.empty, $time);
                pop_here(rd_xtn);
                if(!invalid_read || !invalid_write) begin 
                    if(!(pop_ref.data_in == rd_xtn.data_out))
                        `uvm_error(get_type_name(), $sformatf(
                                        "\n\nScoreboard Error [Data Mismatch]: \n Received Transaction: %d \n Expected Transaction: %d\n",
                                        rd_xtn.data_out, pop_ref.data_in))

                    else 
                        `uvm_info(get_type_name(),$sformatf("\n\n Scoreboard Success [Data Match Successfully] ==> [ DATA OUT = EXP OUT ] : [%0d = %0d]\n",
                            rd_xtn.data_out, pop_ref.data_in),
                            UVM_LOW)
                end

                read_cov_data = rd_xtn;
                read_coverage.sample();
            end
        join

    endtask 
 endclass