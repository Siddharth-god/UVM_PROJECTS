
// rtl 
package fifo_pkg;

parameter WIDTH = 8;
parameter ADDR  = 4;

endpackage


import uvm_pkg::*;
`include "uvm_macros.svh"
import fifo_pkg::*;


module fifo #( 
    parameter WIDTH = fifo_pkg::WIDTH,
    parameter ADDR = fifo_pkg::ADDR
)(
    input  logic clk,
    input  logic rstn,
    input  logic read,
    input  logic write,
    input  logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out,
    output logic full,
    output logic empty
);
    localparam DEPTH = 2**ADDR;

    logic [WIDTH-1:0] fifo_mem [DEPTH-1:0];
    logic [ADDR-1:0]  rdp;
    logic [ADDR-1:0]  wrp;
    logic [ADDR : 0]  count;

    always_ff @(posedge clk) begin
        if(!rstn) begin
            rdp <= 0;
            wrp <= 0;
            count <= 0;
            data_out <= 0;
            for(int i=0; i<DEPTH; i++) begin
                fifo_mem[i] <= 0;
            end
        end
        else begin
            if(read && !empty) begin
                data_out <= fifo_mem[rdp];
                rdp <= rdp + 1;
                count--;
            end

            if(write && !full) begin
                fifo_mem[wrp] <= data_in;
                wrp <= wrp + 1;
                count++;
            end
        end
    end

    assign empty = (count == 0);
    assign full = (count == DEPTH);

endmodule

// Interface 

interface fifo_if #(parameter WIDTH = fifo_pkg::WIDTH)(input bit clk);
    logic rstn;
    logic read;
    logic write;
    logic [WIDTH-1:0] data_in;
    logic [WIDTH-1:0] data_out;
    logic full;
    logic empty;

    clocking wr_drv_cb@(posedge clk);
        default input #1 output #1; 
        output  rstn;
        output  write;
        output  data_in;
    endclocking 

    clocking wr_mon_cb@(posedge clk);
        default input #1 output #1; 
        input  rstn;
        input  write;
        input  data_in;   
        input  full;
        input  empty;  
    endclocking 

    clocking rd_drv_cb@(posedge clk);
        default input #1 output #1; 
        input  rstn; // why input check one more time. 
        output read;  
    endclocking

    clocking rd_mon_cb@(posedge clk);
        default input #1 output #1; 
        input  rstn;
        input read;
        input data_out;
        input full;
        input empty;    
    endclocking

    modport WR_DRV(clocking wr_drv_cb);
    modport WR_MON(clocking wr_mon_cb);
    modport RD_DRV(clocking rd_drv_cb);
    modport RD_MON(clocking rd_mon_cb);
    
endinterface

// Uvm tb 


// Global Config -------------------------------------------------------------------------------

class g_config extends uvm_object;
    `uvm_object_utils(g_config)

    virtual fifo_if #(WIDTH) vif;
    uvm_active_passive_enum is_active; 

    function new(string name = "g_config");
        super.new(name);
    endfunction 

endclass

// Transaction -------------------------------------------------------------------------------

class xtn extends uvm_sequence_item;
    `uvm_object_utils(xtn)

    bit rstn; //-- not a part of transaction so no need to use. 
    rand bit read;
    rand bit write;
    rand bit [WIDTH-1:0] data_in;
    bit [WIDTH-1:0] data_out;
    bit full;
    bit empty;

    function new(string name="xtn");
        super.new(name);
    endfunction 

    virtual function void do_print(uvm_printer printer);
        printer.print_field("data_in",data_in,8,UVM_DEC);
        printer.print_field("write",write,1,UVM_DEC);
        printer.print_field("read",read,1,UVM_DEC);
        printer.print_field("rstn",rstn,1,UVM_DEC);
        printer.print_field("full",full,1,UVM_DEC);
        printer.print_field("empty",empty,1,UVM_DEC);
        printer.print_field("data_out",data_out,8,UVM_DEC);
    endfunction 
endclass 


// Sequence -------------------------------------------------------------------------------

class seq_base extends uvm_sequence #(xtn);
    `uvm_object_utils(seq_base)

    function new(string name="seq_base");
        super.new(name);
    endfunction 
/*
    task body();
        repeat(20) begin 
            req = xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize());
            finish_item(req);
        end
    endtask 
*/
endclass    

// only write / burst write
class seq_write extends seq_base;
       `uvm_object_utils(seq_write)

    function new(string name="seq_write");
        super.new(name);
    endfunction 

    task body();
        //m_sequencer.lock(this);
        repeat(16) begin 
            req = xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {write == 1 && read == 0;});
            finish_item(req);
        end
        //m_sequencer.unlock(this);
    endtask 
endclass 

// only read / burst read 
class seq_read extends seq_base;
       `uvm_object_utils(seq_read)

    function new(string name="seq_read");
        super.new(name);
    endfunction 

    task body();
        //m_sequencer.lock(this);
        repeat(16) begin 
            req = xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {write == 0 && read == 1;});
            finish_item(req);
        end
        //m_sequencer.unlock(this);
    endtask 
endclass 

// random traffic write
class seq_random_wr extends seq_base;
       `uvm_object_utils(seq_random_wr)

    function new(string name="seq_random_wr");
        super.new(name);
    endfunction 

    task body();
        //m_sequencer.lock(this);
        repeat(16) begin 
            req = xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {
                write dist { 1:=50, 0:=50};
            });
            finish_item(req);
        end
        //m_sequencer.unlock(this);
    endtask 
endclass 

// random traffic write
class seq_random_rd extends seq_base;
       `uvm_object_utils(seq_random_rd)

    function new(string name="seq_random_rd");
        super.new(name);
    endfunction 

    task body();
        //m_sequencer.lock(this);
        repeat(16) begin 
            req = xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {
                read dist { 1:=50, 0:=50};
            });
            finish_item(req);
        end
        //m_sequencer.unlock(this);
    endtask 
endclass 


// Sequencer -------------------------------------------------------------------------------
class wr_seqr extends uvm_sequencer #(xtn);
    `uvm_component_utils(wr_seqr)

    function new(string name = "",uvm_component parent);
        super.new(name,parent);
    endfunction

endclass 

class rd_seqr extends uvm_sequencer #(xtn);
    `uvm_component_utils(rd_seqr)
    
    function new(string name = "",uvm_component parent);
        super.new(name,parent);
    endfunction

endclass 

// Virtual seqr -------------------------------------------------------------------------------

class vseqr extends uvm_sequencer #(uvm_sequence_item);
    `uvm_component_utils(vseqr)
    
    function new(string name = "",uvm_component parent);
        super.new(name,parent);
    endfunction

    rd_seqr rseqr;
    wr_seqr wseqr;
endclass

// Virtual seqr -------------------------------------------------------------------------------

class vseq extends uvm_sequence #(uvm_sequence_item);
    `uvm_object_utils(vseq)

    function new(string name="vseq");
        super.new(name);
    endfunction 

    // declare handles for sequences -- handles cannot be declared inside body else error.
    seq_write seq_wrh; 
    seq_read seq_rdh;
    seq_random_wr seq_rdm_wr_h;
    seq_random_rd seq_rdm_rd_h;

    vseqr vseqrh;

    task body();

        // casting to assign parent seqr handle with child seqr handle. 
        if(!$cast(vseqrh, m_sequencer))
            `uvm_fatal(get_full_name(), "Casting failed in Vsequence");

        // create the objects for sequences
        seq_rdh = seq_read::type_id::create("seq_rdh");
        seq_wrh = seq_write::type_id::create("seq_wrh");

        // for random ------
        seq_rdm_wr_h = seq_random_wr::type_id::create("seq_rdm_wr_h");
        seq_rdm_rd_h = seq_random_rd::type_id::create("seq_rdm_rd_h");


        // start sequence on physical sequencer

        // Burst mode ------------------------------------
        $display("\n-----------------------------BURST MODE ON-----------------------------\n\n");
        seq_wrh.start(vseqrh.wseqr);
        seq_rdh.start(vseqrh.rseqr);


        // Simultaneous read and write -------------------

        $display("\n-----------------------------SIMULTANEOUS RW MODE ON-----------------------------\n\n");
        fork
            seq_rdh.start(vseqrh.rseqr);
            seq_wrh.start(vseqrh.wseqr);
        join

        // Random traffic ----------------------------

        $display("\n-----------------------------RANDOM TRAFFIC MODE ON-----------------------------\n\n");
        fork
            seq_rdm_wr_h.start(vseqrh.wseqr);
            seq_rdm_rd_h.start(vseqrh.rseqr);
        join
    endtask
endclass    

// Driver -------------------------------------------------------------------------------
// If Both driver sets reset in interface rstn is x, design breaks --- good question and topic to add on linkdin

class wr_driver extends uvm_driver #(xtn);
    `uvm_component_utils(wr_driver)

    virtual fifo_if #(WIDTH) vif;
    g_config g_cfg; 

    function new(string name = "",uvm_component parent);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(g_config)::get(this,"","g_config",g_cfg))
            `uvm_fatal(get_full_name(),"Cannot get() config from TEST")
    endfunction     

     // connect config vif to vif 
    function void connect_phase(uvm_phase phase);
        vif = g_cfg.vif;
    endfunction    

    task run_phase(uvm_phase phase);

        @(vif.wr_drv_cb) begin 
            vif.wr_drv_cb.rstn <= 0;
            vif.wr_drv_cb.data_in <= 0;
            vif.wr_drv_cb.write <= 0;
        end
        repeat(2) @(vif.wr_drv_cb);

            vif.wr_drv_cb.rstn <= 1; // reset released

        forever begin
            seq_item_port.get_next_item(req);

/* We usually do not use driver print because it makes reading output log harder that it needs to be. 
            
             `uvm_info(get_type_name(),"nDriving transaction", UVM_LOW)
                req.print();
*/
/*            `uvm_info(get_type_name(),
                        $sformatf("\nDriving transaction ==> data_in=%0d | rstn=%0d | write=%0d\n",
                        req.data_in, 
                        req.rstn, 
                        req.write), 
                        UVM_LOW)           
*/
            @(vif.wr_drv_cb) begin 
                vif.wr_drv_cb.rstn <= 1;
                vif.wr_drv_cb.data_in <= req.data_in;
                vif.wr_drv_cb.write <= req.write;
            end

            seq_item_port.item_done();
        end
    endtask

endclass 

class rd_driver extends uvm_driver #(xtn); // read driver cannot control reset else logic breaks
    `uvm_component_utils(rd_driver)

    virtual fifo_if #(WIDTH) vif;
    g_config g_cfg;

    function new(string name = "",uvm_component parent);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(g_config)::get(this,"","g_config",g_cfg))
            `uvm_fatal(get_full_name(),"Cannot get() config from TEST")
    endfunction     

    // connect config vif to vif 
    function void connect_phase(uvm_phase phase);
        vif = g_cfg.vif;
    endfunction

    task run_phase(uvm_phase phase);

        forever begin
            seq_item_port.get_next_item(req);
/*
            `uvm_info(get_type_name(),"nDriving transaction", UVM_LOW)
                req.print();
*/
/*            `uvm_info(get_type_name(),
                        $sformatf("\nDriving transaction ==> read=%0d\n",
                        req.read), 
                        UVM_LOW)
*/
            @(vif.rd_drv_cb)

            if(vif.rd_drv_cb.rstn)
                vif.rd_drv_cb.read <= req.read;

            seq_item_port.item_done();
        end
    endtask

endclass 

// Monitor -------------------------------------------------------------------------------\Logic needs to be written

class rd_monitor extends uvm_monitor;
    `uvm_component_utils(rd_monitor)

    virtual fifo_if #(WIDTH) vif;
    uvm_analysis_port #(xtn) rd_mon_port;
    g_config g_cfg;

    function new(string name = "",uvm_component parent);
        super.new(name,parent);
        rd_mon_port = new("rd_mon_port",this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(g_config)::get(this,"","g_config",g_cfg))
            `uvm_fatal(get_full_name(),"Cannot get() config from TEST")
    endfunction 

    // connect config vif to vif 
    function void connect_phase(uvm_phase phase);
        vif = g_cfg.vif;
    endfunction    

    task run_phase(uvm_phase phase);
        xtn xtnh;
        
        forever begin 
            @(vif.rd_mon_cb)
            
            if(vif.rd_mon_cb.read && !vif.rd_mon_cb.empty) begin 
                xtnh = xtn::type_id::create("xtnh");
                xtnh.read = vif.rd_mon_cb.read;
                xtnh.data_out = vif.rd_mon_cb.data_out;
                xtnh.full = vif.rd_mon_cb.full;
                xtnh.empty = vif.rd_mon_cb.empty;
/*
                `uvm_info(get_type_name(),
                        $sformatf("\nSampling transaction ==> data_out=%0d | read=%0d | full=%0d | empty=%0d\n",
                        xtnh.data_out,
                        xtnh.read, 
                        xtnh.full, 
                        xtnh.empty), 
                        UVM_LOW)
*/
                `uvm_info(get_type_name(),"Sampling transaction", UVM_LOW)
                xtnh.print();

                rd_mon_port.write(xtnh);
            end
        end
    endtask

endclass


class wr_monitor extends uvm_monitor;
    `uvm_component_utils(wr_monitor)

    virtual fifo_if #(WIDTH) vif;
    uvm_analysis_port #(xtn) wr_mon_port;
    g_config g_cfg;

    function new(string name = "",uvm_component parent);
        super.new(name,parent);
        wr_mon_port = new("wr_mon_port",this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(g_config)::get(this,"","g_config",g_cfg))
            `uvm_fatal(get_full_name(),"Cannot get() config from TEST")
    endfunction     

    // connect config vif to vif 
    function void connect_phase(uvm_phase phase);
        vif = g_cfg.vif;
    endfunction

    task run_phase(uvm_phase phase);
        xtn xtnh;

        forever begin 
            @(vif.wr_mon_cb)
            
            if(vif.wr_mon_cb.write && !vif.wr_mon_cb.full)  begin 
                xtnh = xtn::type_id::create("xtnh");
                xtnh.write = vif.wr_mon_cb.write;
                xtnh.data_in = vif.wr_mon_cb.data_in;
                xtnh.rstn = vif.wr_mon_cb.rstn;   // not declared in xtn, directly driving reset to dut from driver.
/*
                `uvm_info(get_type_name(),
                        $sformatf("\nSampling transaction ==> data_in=%0d | rstn=%0d | write=%0d\n",
                        xtnh.data_in,
                        xtnh.rstn, 
                        xtnh.write), 
                        UVM_LOW)
*/
                `uvm_info(get_type_name(),"Sampling transaction", UVM_LOW)
                xtnh.print();

                wr_mon_port.write(xtnh);
            end
        end
    endtask    
endclass

// Agent -------------------------------------------------------------------------------
class wr_agent extends uvm_agent;
    `uvm_component_utils(wr_agent)

    wr_seqr wr_seqr_h;
    wr_monitor wr_monitor_h;
    wr_driver wr_driver_h;

    function new(string name = "",uvm_component parent);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        wr_monitor_h = wr_monitor::type_id::create("wr_monitor_h",this);
        //if(is_active == UVM_ACTIVE) begin 
            wr_driver_h = wr_driver::type_id::create("wr_driver_h",this);
            wr_seqr_h = wr_seqr::type_id::create("wr_seqr_h",this);
        //end
    endfunction    

    function void connect_phase(uvm_phase phase);
        wr_driver_h.seq_item_port.connect(wr_seqr_h.seq_item_export);
    endfunction  

endclass 

class rd_agent extends uvm_agent;
    `uvm_component_utils(rd_agent)

    rd_seqr rd_seqr_h;
    rd_monitor rd_monitor_h;
    rd_driver rd_driver_h;

    function new(string name = "",uvm_component parent);
        super.new(name,parent);

    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        rd_monitor_h = rd_monitor::type_id::create("rd_monitor_h",this);
        //if(is_active == UVM_ACTIVE) begin 
            rd_driver_h = rd_driver::type_id::create("rd_driver_h",this);
            rd_seqr_h = rd_seqr::type_id::create("rd_seqr_h",this);
        //end
    endfunction   

    function void connect_phase(uvm_phase phase);
        rd_driver_h.seq_item_port.connect(rd_seqr_h.seq_item_export);
    endfunction   

endclass 

// Scoreboard -------------------------------------------------------------------------------

class sb extends uvm_scoreboard;

    `uvm_component_utils(sb)

    bit [WIDTH-1:0] exp_op;

    uvm_tlm_analysis_fifo #(xtn) fifo_rd;
    uvm_tlm_analysis_fifo #(xtn) fifo_wr;

    function new(string name="",uvm_component parent);
        super.new(name,parent);
        fifo_rd = new("fifo_rd",this);
        fifo_wr = new("fifo_wr",this);
    endfunction 

    bit [WIDTH-1:0] ref_data [$];

    
    function void exp_out(ref xtn wr_xtn_h, xtn rd_xtn_h);
        
        // queue logic -- ref logic 
        if(wr_xtn_h.write)
            ref_data.push_back(wr_xtn_h.data_in);

        if(ref_data.size() > 0 && rd_xtn_h.read) // without using read also we get correct pop, coz monitor only samples when read is high. Means comparision won't happen unless read is hign means pop won't happen unless read is high. so no need to give read here.
            exp_op = ref_data.pop_front();
        
    endfunction

    task run_phase(uvm_phase phase);
        xtn wr_mon_xtn;
        xtn rd_mon_xtn;

    forever begin 
        fifo_rd.get(rd_mon_xtn);
        fifo_wr.get(wr_mon_xtn);

        if(exp_op == rd_mon_xtn.data_out) begin 
            `uvm_info(get_type_name(),
                            $sformatf("\n[---Data Match successful---] ==> DATA IN = %0d READ = %0d WRITE = %0d RESET = %0d ==> [ DATA OUT = EXP OUT ] : [%0d = %0d]\n",
                                    wr_mon_xtn.data_in,
                                    rd_mon_xtn.read,
                                    wr_mon_xtn.write,
                                    wr_mon_xtn.rstn,
                                    rd_mon_xtn.data_out,
                                    exp_op),
                            UVM_LOW)
        end
        else 
                `uvm_error(get_type_name(), $sformatf(
                            "\n\nScoreboard Error [Data Mismatch]: \n Received Transaction: %d \n Expected Transaction: %d\n",
                            rd_mon_xtn.data_out, exp_op));


                exp_out(wr_mon_xtn, rd_mon_xtn);
    end

    endtask

endclass 
// Environment -------------------------------------------------------------------------------
class env extends uvm_env;
    `uvm_component_utils(env)

    rd_agent rd_agent_h;
    wr_agent wr_agent_h;
    sb sbh;
    vseqr vseqrh;

    function new(string name = "",uvm_component parent);
        super.new(name,parent);

    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sbh = sb::type_id::create("sbh",this);
        rd_agent_h = rd_agent::type_id::create("rd_agent_h",this);
        wr_agent_h = wr_agent::type_id::create("wr_agent_h",this);
        vseqrh = vseqr::type_id::create("vseqrh",this);
    endfunction  

    function void connect_phase(uvm_phase phase);
        // connect vseqr seqr's and agent seqr's
        vseqrh.rseqr = rd_agent_h.rd_seqr_h;
        vseqrh.wseqr = wr_agent_h.wr_seqr_h; 

        // connect analysis port and analysis fifo
        rd_agent_h.rd_monitor_h.rd_mon_port.connect(sbh.fifo_rd.analysis_export);
        wr_agent_h.wr_monitor_h.wr_mon_port.connect(sbh.fifo_wr.analysis_export);
    endfunction   

endclass 

// Test -------------------------------------------------------------------------------
class test extends uvm_test;
    `uvm_component_utils(test)

    env envh;
    g_config g_cfg;
    vseq vseqh;

    function new(string name = "",uvm_component parent);
        super.new(name,parent);
    endfunction

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

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction 

    task run_phase(uvm_phase phase);
        // seq_base seqh;

            phase.raise_objection(this);

            //seqh = seq_base::type_id::create("seqh");
            
            // start seq on physical seqr's
            /* 
            seqh.start(envh.wr_agent_h.wr_seqr_h);
            seqh.start(envh.rd_agent_h.rd_seqr_h);
            */

            vseqh.start(envh.vseqrh);

            phase.drop_objection(this);
    endtask 


endclass 

module uvm_fifo;

    bit clk = 0;

    parameter WIDTH = 8;
    parameter ADDR  = 4;
    
    always #5 clk = ~clk;

    fifo_if #(WIDTH) IF(clk);

    fifo #(
        .WIDTH(WIDTH),
        .ADDR(ADDR)
        ) DUT(
        .clk(clk),
        .rstn(IF.rstn),
        .data_in(IF.data_in),
        .data_out(IF.data_out),
        .read(IF.read),
        .write(IF.write),
        .full(IF.full),
        .empty(IF.empty)
    );

    initial begin 
        uvm_config_db #(virtual fifo_if #(WIDTH))::set(null,"*","fifo_if",IF);
        run_test("test"); 
    end
endmodule 


/*
`uvm_info(get_type_name(),
                            $sformatf("\n[---Data Match successful---] ==> DATA IN = %0d READ = %0d WRITE = %0d RESET = %0d ==> [ DATA OUT = EXP OUT ] : [%0d = %0d]\n",
                                    wr_mon_xtn.data_in,
                                    rd_mon_xtn.read,
                                    wr_mon_xtn.write,
                                    wr_mon_xtn.rstn,
                                    rd_mon_xtn.data_out,
                                    exp_op),
                            UVM_LOW)
*/