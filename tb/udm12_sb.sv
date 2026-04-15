// Scoreboard -----------------------------------------------------------------------------------------
class sb extends uvm_scoreboard;

    `uvm_component_utils(sb)

    uvm_tlm_analysis_fifo #(xtn) fifo_driver_mon_port;
    uvm_tlm_analysis_fifo #(xtn) fifo_sampler_mon_port;

    xtn udm_cov1; 
    xtn udm_cov2; 

    bit [3:0] exp_op;

    covergroup udm_cg;
        DATA_IN : coverpoint udm_cov1.data_in{
            bins low = {[0:3]};
            bins mid = {[4:7]};
            bins high = {[8:11]};
        }
        RSTN : coverpoint udm_cov1.rstn;
        LOAD : coverpoint udm_cov1.load;
        MODE : coverpoint udm_cov1.mode; 

        DATA_OUT : coverpoint udm_cov2.data_out{
            bins low = {[0:3]};
            bins mid = {[4:7]};
            bins high = {[8:11]};
        }

        DIN_x_LD : cross DATA_IN, LOAD; 
        DIN_x_MD : cross DATA_IN, MODE;
        DIN_x_DOUT : cross DATA_IN, DATA_OUT;

    endgroup 

    
    function new(string name, uvm_component parent);
        super.new(name,parent);
        fifo_driver_mon_port = new("fifo_driver_mon_port",this); // Remember second argument "this" is very important here. 
        fifo_sampler_mon_port = new("fifo_sampler_mon_port",this);

        udm_cg = new();
    endfunction 


    function void exp_out(xtn xtn_h);

        if(!xtn_h.rstn)
            exp_op = 4'd0;
        else if(xtn_h.load)   
            exp_op = xtn_h.data_in;
        else if(xtn_h.mode == 1)
            begin 
                if(exp_op == 11)
                    exp_op = 4'd0;
                else    
                    exp_op = exp_op + 1'b1;
            end
        else begin 
            if(exp_op == 0)
                exp_op = 4'd11;
            else 
                exp_op = exp_op - 1'b1;  
        end
    endfunction 

    task run_phase(uvm_phase phase);
        xtn in_xtn;
        xtn out_xtn;
            forever begin 
                fifo_driver_mon_port.get(in_xtn);
                fifo_sampler_mon_port.get(out_xtn);

                udm_cov1 = in_xtn; 
                udm_cov2 = out_xtn;

                if(exp_op == out_xtn.data_out)  
                    `uvm_info(get_type_name(),
                                $sformatf("\n[---Data Match successful---] ==> DATA IN = %0d MODE = %0d LOAD = %0d RESET = %0d ==> [ DATA OUT = EXP OUT ] : [%0d = %0d]\n",
                                        in_xtn.data_in,
                                        in_xtn.mode,
                                        in_xtn.load,
                                        in_xtn.rstn,
                                        out_xtn.data_out,
                                        exp_op),
                                UVM_LOW)  
                else 
                    `uvm_error(get_type_name(), $sformatf(
                                "\n\nScoreboard Error [Data Mismatch]: \n Received Transaction: %d \n Expected Transaction: %d\n",
                                out_xtn.data_out, exp_op));
                udm_cg.sample();
                exp_out(in_xtn);     
            end         
    endtask 

endclass 
