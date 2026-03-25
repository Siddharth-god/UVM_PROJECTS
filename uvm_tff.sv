
import uvm_pkg::*;
`include "uvm_macros.svh"

module tff (
    input  logic clk,
    input  logic rstn,   // active low reset
    input  logic t,
    output logic q
);

    always_ff @(posedge clk) begin
        if (!rstn)
            q <= 1'b0;
        else if (t)
            q <= ~q;      // toggle
        else
            q <= q;       // hold
    end
endmodule

// Interface we write with TB pov not DUT

/*
vif is shared.So monitor sees whatever driver drove because both access same wires. There is no drv→mon connection. The interface is the shared medium.
*/
interface tff_if(input bit clk); 

    logic rstn;
    logic t;
    logic q;

    // Clocking block for DRIVER (drives inputs)
    clocking drv_cb @(posedge clk);
        //default input #1 output #1;
        output t;
        output rstn;
        input  q;
    endclocking

    // Clocking block for MONITOR (samples signals)
    clocking mon_cb @(posedge clk);
        default input #1 output #1;
        input t;
        input rstn;
        input q;
    endclocking

    // Modports referencing clocking blocks
    modport DRV (clocking drv_cb);
    modport MON (clocking mon_cb);
endinterface

// UVM_TB  TFF 

class xtn extends uvm_sequence_item;

    `uvm_object_utils(xtn)

    rand bit t;
    bit rstn;
    bit q;

    function new(string name = "xtn");
        super.new(name);
    endfunction 

    constraint valid_vals{
        t dist {1 := 5, 0 := 5};
        //rstn dist {1 := 9, 0 := 1};
    }

    function void do_copy(uvm_object rhs);
        xtn rhs_;
        if(!$cast(rhs_, rhs))
            `uvm_fatal("COPY","Cast failed");

        super.do_copy(rhs);

        t    = rhs_.t;
        rstn = rhs_.rstn;
        q    = rhs_.q;
    endfunction

    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        // we don't need this here for this design
    endfunction 

    virtual function void do_print(uvm_printer printer);
        super.do_print(printer);
        printer.print_field("t",    t,    1, UVM_DEC);
        printer.print_field("rstn", rstn, 1, UVM_DEC);
        printer.print_field("q",    q,    1, UVM_DEC);
    endfunction

endclass 

class seq extends uvm_sequence #(xtn);

    `uvm_object_utils(seq)

    function new(string name = "seq");
        super.new(name);
    endfunction

    task body();
        repeat(10) begin
            req = xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize());
            finish_item(req);
        end
    endtask
endclass 


class seqr extends uvm_sequencer #(xtn);

    `uvm_component_utils(seqr)

    

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction 


endclass 


class driver extends uvm_driver #(xtn);

    `uvm_component_utils(driver)

    //virtual tff_if.DRV vif;
    virtual tff_if vif;

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if(!uvm_config_db #(virtual tff_if)::get(this,"","tff_if",vif))
            `uvm_fatal("DRIVER","cannot get() vif from TOP")
//------------------------------------------------------------------------------------------------------------------------------------
// IMPORTANT:
//------------------------------------------------------------------------------------------------------------------------------------
// The type used in uvm_config_db::set() must EXACTLY match the type used in uvm_config_db::get().
// If set() uses: uvm_config_db#(virtual tff_if)
// Then get() must also use: uvm_config_db#(virtual tff_if)
// If get() uses virtual tff_if.DRV or .MON, then set() must use the same exact modport type.
// Even a small type difference (like using full interface in set and modport in get) will cause get() to fail silently and return 0.
// Always ensure SET and GET types are identical.
//------------------------------------------------------------------------------------------------------------------------------------
    endfunction 

    task run_phase(uvm_phase phase);

        // Initial reset sequence
        @(vif.drv_cb);
        vif.drv_cb.rstn <= 0;
        vif.drv_cb.t    <= 0;

        // Hold reset low for a few cycles
        repeat (3) @(vif.drv_cb);

        // Release reset
        @(vif.drv_cb);
        vif.drv_cb.rstn <= 1;

        // Now drive transactions forever
        forever begin
            seq_item_port.get_next_item(req);

            `uvm_info("DRIVER", "Driving transaction:", UVM_LOW)
            req.print();

            @(vif.drv_cb);
            vif.drv_cb.t <= req.t;
            // keep reset stable high during normal operation
            vif.drv_cb.rstn <= 1;

            seq_item_port.item_done();
        end

    endtask
endclass 


class monitor extends uvm_monitor;

    `uvm_component_utils(monitor)

    //virtual tff_if.MON vif;
    virtual tff_if vif;
   
    uvm_analysis_port #(xtn) monitor_port;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if(!uvm_config_db #(virtual tff_if)::get(this,"","tff_if",vif))
            `uvm_fatal("MONITOR","cannot get() vif from TOP")
    endfunction 

    function new(string name, uvm_component parent);
        super.new(name,parent);
        monitor_port = new("monitor_port",this);
    endfunction 

    task run_phase(uvm_phase phase);

        xtn sample_dut;

        forever begin 
            //repeat(2)
            
            @(vif.mon_cb)  

                if(vif.mon_cb.rstn) begin 
                    sample_dut = xtn::type_id::create("sample_dut");
                    sample_dut.q = vif.mon_cb.q;
                    sample_dut.t = vif.mon_cb.t;
                    sample_dut.rstn = vif.mon_cb.rstn;

                    `uvm_info("WR_MONITOR","Captured transaction",UVM_LOW) // after sampeling we can print this is the best place to print
                    sample_dut.print();

                    monitor_port.write(sample_dut); // does this comes inside the forever begin ?
                end 
        end
    endtask 


endclass 


class agent extends uvm_agent;

    `uvm_component_utils(agent)

    seqr seqrh;
    driver drvh;
    monitor monh;

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        seqrh = seqr::type_id::create("seqrh",this);
        drvh = driver::type_id::create("drvh",this);
        monh = monitor::type_id::create("monh",this);
        
    endfunction 

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        drvh.seq_item_port.connect(seqrh.seq_item_export);
    endfunction

endclass 


class sb extends uvm_scoreboard;

    `uvm_component_utils(sb)

    uvm_tlm_analysis_fifo #(xtn) fifo_mon_port;
    xtn xtnh;
    bit exp_q;
    
    function new(string name, uvm_component parent);
        super.new(name,parent);
        fifo_mon_port = new("fifo_mon_port",this); // Remember second argument "this" is very important here. 
    endfunction 

    function void exp_out(ref xtn xtn_h);

        if(!xtn_h.rstn) begin 
            exp_q = 0;
        end
        else if(xtn_h.t)
            exp_q = ~ exp_q;
        else 
            exp_q = exp_q;

    endfunction 

    task run_phase(uvm_phase phase);
        forever begin
            fifo_mon_port.get(xtnh); //  acts as clock edge 
            

            if(exp_q == xtnh.q)
                `uvm_info(get_type_name(), $sformatf("Scoreboard - Data Match successful"), UVM_MEDIUM)
            else 
                `uvm_error(get_type_name(), $sformatf(
                            "\n Scoreboard Error [Data Mismatch]: \n Received Transaction: %d \n Expected Transaction: %d",
                            xtnh.q, exp_q));
            
            exp_out(xtnh);
            
        end
    endtask 

endclass 


class env extends uvm_env;

    `uvm_component_utils(env)

    agent agnth;
    sb sb_h;

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agnth = agent::type_id::create("agnth",this);
        sb_h = sb::type_id::create("sb_h",this);
    endfunction 

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // connect monitor analysis port with fifo tlm port
        agnth.monh.monitor_port.connect(sb_h.fifo_mon_port.analysis_export);
    endfunction 

endclass 

class test extends uvm_test;

    `uvm_component_utils(test)

    env envh;

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        envh = env::type_id::create("envh",this);
    endfunction 

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

    task run_phase(uvm_phase phase);

        seq seqh;

        phase.raise_objection(this);
        #100;
        seqh = seq::type_id::create("seqh");
        seqh.start(envh.agnth.seqrh);
        phase.drop_objection(this);
    endtask 
endclass 



module uvm_tb_tff;

    bit clk = 0;
    int cc = 10;

    tff_if T_FF(clk);

    tff DUT(
        .t(T_FF.t),
        .rstn(T_FF.rstn),
        .clk(clk),
        .q(T_FF.q)
    );

    always #(cc/2) clk = ~clk;

    initial begin 
        uvm_config_db #(virtual tff_if)::set(null,"*","tff_if",T_FF);
        run_test("test");
    end
endmodule 

//----------------------------------------------------END---------------------------------------------------------//