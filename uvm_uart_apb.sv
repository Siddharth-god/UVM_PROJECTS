

import uvm_pkg::*;
`include "uvm_macros.svh"

//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx RTL xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------RTL-------------------------------------------------------


//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx INTERFACE xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------APB INTERFACE-------------------------------------------------------
interface apb_if(input bit PCLK);
    
    logic PRESETn;
    logic [31:0] PADDR;
    logic [31:0] PRDATA;
    logic [31:0] PWDATA;
    logic PENABLE;
    logic PREADY;
    logic PSEL;
    logic PWRITE;
    logic PSLVERR;  
    logic IRQ;                                   
                                                                                             
                                                                                             
    clocking apb_drv_cb@(posedge PCLK);

        output PRESETn;
        output PADDR;
        output PWDATA;
        output PENABLE;
        output PSEL;
        output PWRITE;
        input  PREADY;
        input  IRQ;
        input  PRDATA;
    endclocking 

    clocking apb_mon_cb@(posedge PCLK);
        
        input PRESETn;
        input PADDR;
        input PWDATA;
        input PENABLE;
        input PSEL;
        input PWRITE;
        input PSLVERR;
        input PREADY;
        input PRDATA;
        input IRQ;
    endclocking 
                                                                                             
                                                                                             
    modport APB_DRV_MD(clocking apb_drv_cb);
    modport APB_MON_MD(clocking apb_mon_cb);                                     
                                             
endinterface 
//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx TRANSACTIONS xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------APB TRANSACTION-------------------------------------------------------
class apb_xtn extends uvm_sequence_item;
    `uvm_object_utils(apb_xtn)

    function new(string name="apb_xtn");
        super.new(name);
    endfunction 

    bit PRESETn;
    bit PCLK;
    rand bit [31:0] PADDR;
    bit [31:0] PRDATA;
    rand bit [31:0] PWDATA;
    bit PENABLE;
    bit PREADY;
    bit PSEL;
    rand bit PWRITE;
    bit PSLVERR;
    bit IRQ;

    // Registers 
    bit [7:0] THR [$];                                          
    bit [7:0] RBR [$];                                          
    bit [15:0] DIV;                                          
    bit [7:0] LCR;                                          
    bit [7:0] IER;                                          
    bit [7:0] LSR; 
    //bit [7:0] IRQ;                                          
    bit [7:0] IIR; // Default val of IIR is 0, Not C1. So,it cannot be MODEM CONTROL REG                                       
    bit [7:0] FCR;                                          
    bit [7:0] MSR;
    bit [7:0] MCR;    
    
    // signals 
    bit dl_access; 
    bit data_in_thr; // for this we should use IIR right ???
    bit data_in_rbr;

                   
    // Print method 

    virtual function void do_print(uvm_printer printer);
        printer.print_field("PCLK",    PCLK,    1,   UVM_DEC);
        printer.print_field("PRESETn", PRESETn, 1,   UVM_DEC);
        printer.print_field("PADDR",   PADDR,   32,  UVM_DEC);
        printer.print_field("PRDATA",  PRDATA,  32,  UVM_DEC);
        printer.print_field("PWDATA",  PWDATA,  32,  UVM_DEC);
        printer.print_field("PENABLE", PENABLE, 1,   UVM_DEC);
        printer.print_field("PREADY",  PREADY,  1,   UVM_DEC);
        printer.print_field("PSEL",    PSEL,    1,   UVM_DEC);
        printer.print_field("PWRITE",  PWRITE,  1,   UVM_DEC);
        printer.print_field("PSLVERR", PSLVERR, 1,   UVM_DEC);
    endfunction 


endclass 

//-----------------------------------------------------UART TRANSACTION------------------------------------------------------
class uart_xtn extends uvm_sequence_item;
    `uvm_object_utils(uart_xtn)

    function new(string name="uart_xtn");
        super.new(name);
    endfunction 

    bit START;
    bit UCLK;
    bit [7:0] UDATA;
    bit PARITY;
    bit [1:0] STOP;
                                                                      
    // Print method 

    virtual function void do_print(uvm_printer printer);
        printer.print_field("UCLK",    UCLK,    1,   UVM_DEC);
        printer.print_field("START",   START,   1,   UVM_DEC);
        printer.print_field("UDATA",   UDATA,   8,   UVM_DEC);
        printer.print_field("STOP",    STOP,    2,  UVM_DEC);
        printer.print_field("PARITY",  PARITY,  1,   UVM_DEC);
    endfunction
endclass 

//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx SEQUENCES xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------APB SEQS-------------------------------------------------------
class apb_seq_base extends uvm_sequence #(apb_xtn);
    `uvm_object_utils(apb_seq_base)

    function new(string name="apb_seq_base");
        super.new(name);
    endfunction

    // Reusable write 
    task do_write(bit[31:0]addr, bit[31:0]data);
        start_item(req);
        assert(req.randomize() with {PADDR==addr; PWRITE==1; PWDATA==data;});
        finish_item(req);
    endtask

    // Reusable read 
    task do_read(bit[31:0]addr);
        start_item(req);
        assert(req.randomize() with {PADDR==addr; PWRITE==0;});
        finish_item(req);
    endtask

    // Flexible config task
    task uart_reg_config(
        bit[7:0] lcr_val = 8'b0000_0011,
        bit[7:0] fcr_val = 8'b0000_0110,
        bit[7:0] ier_val = 8'b0000_0101,
        int divisor = 27
    );
        // DIVISOR MSB
        do_write(32'h20, divisor[15:8]); // this divisor value will be 0, as 27 is not in the range for this.

        // DIVISOR LSB
        do_write(32'h1C, divisor[7:0]);  // 27 will automatically falls inside 7:0

        // LCR REG - Flexibal
        do_write(32'hC, lcr_val); //--> Used to configure the data size and behaviour

        // FCR REG - Flexibal
        do_write(32'h08, fcr_val); // FCR = 8'b0000_0110; This resets FIFO every sequence start - This does not check real behaviour. 
 
        // IER REG - Flexibal
        do_write(32'h04, ier_val);
    endtask
endclass 


// half duplex ------------------------------
class half_duplex extends apb_seq_base;
    `uvm_object_utils(half_duplex)

    function new(string name="half_duplex");
        super.new(name);
    endfunction

    task body();
        req = apb_xtn::type_id::create("req");

    // Why Divisor latch we have configured first ?? --> DVL decides the baud rate for the UART so it must be confgured first.
        // DIVISOR LATCH REG - MSB
        start_item(req);
        assert(req.randomize() with {PADDR==32'h20; PWRITE==1; PWDATA==0;});
        finish_item(req);

        // DIVISOR LATCH REG - LSB
        start_item(req);
        assert(req.randomize() with {PADDR==32'h1C; PWRITE==1; PWDATA==27;}) // 27 is the value of baud rate we have generated, using frequency. Another side value will be generated in the TOP module, because another UART side is not a DUT it is AGENT in our case so we cannot drive the value to agent, we have to take it from TOP using CONFIG class. 
        finish_item(req); // mam passing 54 as pwdata for div lsb

        // LINE CONTROL REG --> Used to configure the data size and behaviour
        start_item(req);
        assert(req.randomize() with {PADDR==32'hC; PWRITE==1; PWDATA==8'b0000_0011;})
        finish_item(req);

        // FIFO (ENABLE)CONTROL REG --> Resetting the receiver and tranasmitter (1'st bit = Receiver Reset & 2'nd bit = Transmitter Reset)
        start_item(req);
        assert(req.randomize() with {PADDR==32'h08; PWRITE==1; PWDATA==8'b0000_0110;})
        finish_item(req);

        // INTERRUPT ENABLE --> bit 0 = Received data avaliable interrupt | bit 1 = THR Empty interrupt | bit 2 = Receiver Line status Interrupt
        start_item(req);
        assert(req.randomize() with {PADDR==32'h04; PWRITE==1; PWDATA==8'b0000_0101;})
        finish_item(req);

        // THR REG --> 
        start_item(req);
        assert(req.randomize() with {PADDR==32'h0; PWRITE==1; PWDATA==5;})
        finish_item(req);

    endtask
endclass 

//------------------------------------------------ READ SEQUENCE ------------------------------------------------
class apb_read_seq extends apb_seq_base; 
    `uvm_object_utils(apb_read_seq)

    function new(string name="apb_read_seq");
        super.new(name);
    endfunction

    task body();
        super.body(); 
        req = apb_xtn::type_id::create("req");

        // FIFO CONTROL REG --> 
        start_item(req);
        assert(req.randomize() with {PADDR==32'h08; PWRITE==0;}) // IIR is Read only reg. 
        finish_item(req);
        get_response(req); // getting the response from driver, when driver samples it. 

        if(req.IIR == 4) begin // When IIR == 0x4 (Interrupt --> RECEIVED DATA AVAILABLE ==> Read from RBR)
        // RBR  
        start_item(req);
        assert(req.randomize() with {PADDR==32'h0; PWRITE==0;})
        finish_item(req);
        end

        if(req.IIR == 6) begin // When IIR == 0x4 (Interrupt --> READ LINE STATUS REG => Overrun,parity,framing,break errors)
        // RBR  
        start_item(req);
        assert(req.randomize() with {PADDR==32'h14; PWRITE==0;})
        finish_item(req);
        end
    endtask
endclass 


//------------------------------------------------ FULL DUPLEX SEQUENCE ------------------------------------------------
class full_duplex extends apb_seq_base;
    `uvm_object_utils(full_duplex)

    function new(string name="full_duplex");
        super.new(name);
    endfunction

    task body();
        req = apb_xtn::type_id::create("req");

        uart_reg_config();

        // THR REG --> 
        fork
            do_write(32'h0, 32'h55); // transmit 
            do_read(32'h0); // Receive 
        join

    endtask
endclass 


//------------------------------------------------ LOOPBACK SEQUENCE ------------------------------------------------
class loopback extends apb_seq_base;
    `uvm_object_utils(loopback)

    function new(string name="loopback");
        super.new(name);
    endfunction

    task body();
        req = apb_xtn::type_id::create("req");

        uart_reg_config();

        do_write(32'h10, 8'b0001_0000); // MCR loopback enable [5th bit for loopback] (do write can take upto 32 bits but we can also give 8 bits other will become 0)

        do_write(32'h0, 32'h5A); // THR → data goes into TX → looped back internally → appears in RX 
        do_read(32'h0); // And we also need to read the value that we pass (as loopback gives same value back)
// NOTE : loop back gets read on the same UART side cannot be sent to another uart. 
    endtask
endclass 


//------------------------------------------------ PARITY ERR SEQUENCE ------------------------------------------------
class parity_seq extends apb_seq_base;
    `uvm_object_utils(parity_seq)

    function new(string name="parity_seq");
        super.new(name);
    endfunction

    task body();
        req = apb_xtn::type_id::create("req");

        uart_reg_config(.lcr_val(8'b0000_1011)); // Parity enable [odd parity]

        do_write(32'h0, 32'h33);
// NOTE : Parity is checked on another UART, so no need to read here. 
    endtask
endclass 


//------------------------------------------------ BREAK ERR SEQUENCE ------------------------------------------------
class break_req extends apb_seq_base;
    `uvm_object_utils(break_req)

    function new(string name="break_req");
        super.new(name);
    endfunction

    task body();
        req = apb_xtn::type_id::create("req");

        uart_reg_config(.lcr_val(8'b0100_0011)); // Break Enable 

        do_write(32'h0, 32'h00); // THR --> Privide 00 with parity enable to check if UART gives the break error

// NOTE : We don't read anything (check happens in another UART)
    endtask
endclass 


//------------------------------------------------ OVERRUN ERR SEQUENCE ------------------------------------------------
class overrun_seq extends apb_seq_base;
    `uvm_object_utils(overrun_seq)

    function new(string name="overrun_seq");
        super.new(name);
    endfunction

    task body();
        req = apb_xtn::type_id::create("req");

        uart_reg_config();

        repeat(17) // Flooding THR to check the Overrun error. (FIFO) capacity 16
            do_write(32'h0, $urandom_range(0,255));  

    endtask
endclass 



//------------------------------------------------ THR_EMPTY SEQUENCE ------------------------------------------------
class thr_empty_seq extends apb_seq_base;
    `uvm_object_utils(thr_empty_seq)

    function new(string name="thr_empty_seq");
        super.new(name);
    endfunction

    task body();
        req = apb_xtn::type_id::create("req");

        uart_reg_config();

        do_write(32'h0, 8'hAA);

         do_read(32'h08); // Reading IIR 
        // Alternate way => 
        // do_read(32'h14);
        get_response(req); // From Driver getting the response 

        if(req.IIR == 2) begin // Wait till IIR is 2 ==> When another side UART reads everything this will hit. 
            `uvm_info(get_type_name(), "THR EMPTY interrupt received", UVM_MEDIUM) //===? IER to enable hi nahi hoga to how we will get this interrupt 
        end
        //Alternate => 
        // if(req.IIR == 2) begin 
        //     do_read(32'h14);  // Reading LSR when IIR empty, then In SB we can check.(No need to do this way)
        // end
        
    endtask
endclass 


//------------------------------------------------ FRAMING ERR SEQUENCE ------------------------------------------------
class framing_seq extends apb_seq_base;
    `uvm_object_utils(framing_seq)

    function new(string name="framing_seq");
        super.new(name);
    endfunction

    task body();
        req = apb_xtn::type_id::create("req");

        // 2 stop bits (can mismatch with other side)
        uart_reg_config(.lcr_val(8'b0000_0111));

        do_write(32'h0, 8'hF0);
    endtask
endclass 


//------------------------------------------------ TIMEOUT ERR SEQUENCE ------------------------------------------------
class timeout_seq extends apb_seq_base;
    `uvm_object_utils(timeout_seq)

    function new(string name="timeout_seq");
        super.new(name);
    endfunction

    task body();
        req = apb_xtn::type_id::create("req");

        uart_reg_config();

        // Putting data (simulate RX pending)
        do_write(32'h0, 8'h55);

        // Not Reading Intentionally

        // checks interrupt
        do_read(32'h08);
        get_response(req);

        if(req.IIR == 8'hC) begin // Wait till interrupt - No read happens => Time out error
            `uvm_info(get_type_name(), "TIMEOUT interrupt received", UVM_MEDIUM)
        end

    endtask
endclass 

//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx CONFIGS xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------APB CONFIG-------------------------------------------------------
// agent Config class 
class apb_agent_config extends uvm_object;
    `uvm_object_utils(apb_agent_config)

    function new(string name="apb_agent_config");
        super.new(name);
    endfunction 

    virtual apb_if vif; 
    uvm_active_passive_enum is_active = UVM_ACTIVE;

endclass 

//-----------------------------------------------------UART CONFIG------------------------------------------------------
class uart_agent_config extends uvm_object;
    `uvm_object_utils(uart_agent_config)

    function new(string name="uart_agent_config");
        super.new(name);
    endfunction 

    virtual apb_if vif; 
    uvm_active_passive_enum is_active = UVM_ACTIVE;
endclass 

//-----------------------------------------------------ENV CONFIG------------------------------------------------------
class env_config extends uvm_object;
    `uvm_object_utils(env_config)

    uart_agent_config uart_cfg; 
    apb_agent_config apb_cfg;

    function new(string name="env_config");
        super.new(name);
    endfunction 

    virtual apb_if vif; 

    int has_apb_agent;
    int has_uart_agent; 
    int has_sb;

endclass


//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx SEQRS xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------APB SEQR-------------------------------------------------------
class apb_seqr extends uvm_sequencer #(apb_xtn);
    `uvm_component_utils(apb_seqr)

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 
    
endclass 

//-----------------------------------------------------UART SEQR------------------------------------------------------

class uart_seqr extends uvm_sequencer #(uart_xtn);
    `uvm_component_utils(uart_seqr)

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 

endclass 

// Virtual seq --------------------------------------------------------------------------

class vseq extends uvm_sequence #(uvm_sequence_item);
    `uvm_object_utils(vseq)

    function new(string name="vseq");
        super.new(name);
    endfunction

endclass 

// Virtual seqr --------------------------------------------------------------------------

class vseqr extends uvm_sequencer #(uvm_sequence_item);
    `uvm_component_utils(vseqr)

    function new(string name="",uvm_component parent);
        super.new(name, parent);
    endfunction

endclass 

//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx DRIVERS xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------APB DRIVER-------------------------------------------------------
class apb_drv extends uvm_driver #(apb_xtn);
    `uvm_component_utils(apb_drv)

    apb_agent_config apb_cfg; 
    virtual apb_if vif; 

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase); 
        if(!uvm_config_db #(apb_agent_config)::get(this,"","apb_agent_config",apb_cfg))
            `uvm_fatal(get_type_name(),"Failed to get apb_cfg from ENV")

    endfunction 

    function void connect_phase(uvm_phase phase);
        vif = apb_cfg.vif; 
    endfunction 

    task run_phase(uvm_phase phase);
        @(vif.apb_drv_cb);
            vif.apb_drv_cb.PRESETn <= 0;
        @(vif.apb_drv_cb);
            vif.apb_drv_cb.PRESETn <= 1;
        forever begin 
            seq_item_port.get_next_item(req);
            send_to_dut(req);
            seq_item_port.item_done();
        end
    endtask 

    task send_to_dut(apb_xtn xtn_h);
        @(vif.apb_drv_cb);
            vif.apb_drv_cb.PWRITE   <= xtn_h.PWRITE; // Because this is randomized
            vif.apb_drv_cb.PWDATA   <= xtn_h.PWDATA; // Because this is randomized
            vif.apb_drv_cb.PADDR    <= xtn_h.PADDR;  // Because this is randomized
            vif.apb_drv_cb.PSEL     <= 1;
            vif.apb_drv_cb.PENABLE  <= 0; // SETUP STATE --> PENB = 0 & PSEL = 1
        
        @(vif.apb_drv_cb);
            vif.apb_drv_cb.PENABLE  <= 1; // After 1 cc GO TO ACCESS state. 
        
        @(vif.apb_drv_cb); // Ask mam - how and from where PREADY comes from slave right ?? So how can we use driver ? 
            while(!vif.apb_drv_cb.PREADY) // Waiting For Slave to be READY to RECEIVE the DATA.
            //==> If PREADY is 1, move to next state (otherwise wait for 1cc) --> while declares continuity (means if PREADY is 0 keep waiting)
                @(vif.apb_drv_cb);

        
        // IIR Register --> Address == 0x8 and IIR is READ ONLY so PWRITE == 0. If PWRITE == 1 => FCR 
        if(xtn_h.PADDR == 32'h8 && xtn_h.PWRITE == 0) begin
            while(!vif.apb_drv_cb.IRQ === 0) // Wait for the interrupt - (if no interrupt high --> Keep waiting) => IRQ tells there is an Interrupt when it is HIGH.
                @(vif.apb_drv_cb); 

        xtn_h.IIR = vif.apb_drv_cb.PRDATA; // Sample the IIR register value, So that sequence can be generated according to IIR value. ----> We are using response method of DRIVER. (So sampling is done in DRIVER)
        seq_item_port.put_response(xtn_h);
    end
        vif.apb_drv_cb.PSEL     <= 0; // Go to IDLE
        vif.apb_drv_cb.PENABLE  <= 0;
    endtask


endclass 

//-----------------------------------------------------UART DRIVER------------------------------------------------------
class uart_drv extends uvm_driver #(uart_xtn);
    `uvm_component_utils(uart_drv)

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 

endclass 

//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx MONITORS xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------APB MONITOR-------------------------------------------------------
class apb_mon extends uvm_monitor;
    `uvm_component_utils(apb_mon)

    apb_agent_config apb_cfg;
    virtual apb_if vif;
    apb_xtn xtn_h;

    uvm_analysis_port #(apb_xtn) mon_port;

    function new(string name="",uvm_component parent);
        super.new(name,parent);
        mon_port = new("mon_port",this);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(apb_agent_config)::get(this,"","apb_agent_config",apb_cfg))
            `uvm_fatal(get_type_name(),"Failed to get() apb_cfg from ENV")

        // Create transaction object ==> can also be done directly in run_phase
        xtn_h = apb_xtn::type_id::create("xtn_h");

    endfunction 

    function void connect_phase(uvm_phase phase);
        vif = apb_cfg.vif;
    endfunction 

    task run_phase(uvm_phase phase);
        forever begin : monitor_loop
            collect_data();
        end : monitor_loop
    endtask

    //Task Collect Data --------------------------------------
    task collect_data(); 
        @(vif.apb_mon_cb)

        while(vif.apb_mon_cb.PENABLE !== 1) // Wait for enable to become HIGH
            @(vif.apb_mon_cb)
        
            begin : transfer_capture
                while(vif.apb_mon_cb.PREADY !== 1) // Wait for ready to become HIGH
                    @(vif.apb_mon_cb)

                // Sample all the signals 
                    xtn_h.PENABLE = vif.apb_mon_cb.PENABLE;
                    xtn_h.PRESETn = vif.apb_mon_cb.PRESETn;
                    xtn_h.PSEL    = vif.apb_mon_cb.PSEL;
                    xtn_h.PSLVERR = vif.apb_mon_cb.PSLVERR;
                    xtn_h.PADDR   = vif.apb_mon_cb.PADDR;
                    xtn_h.PWRITE  = vif.apb_mon_cb.PWRITE;
                    xtn_h.IRQ     = vif.apb_mon_cb.IRQ;

                // Sample data phase
                if(xtn_h.PWRITE == 1)
                    xtn_h.PWDATA = vif.apb_mon_cb.PWDATA;
                else 
                    xtn_h.PRDATA = vif.apb_mon_cb.PRDATA;

                // Register Updates based on address decoding 
                    //==> We sample all the configured registers (in seq we did) to check whether the configuration happened correctly. We compare in SB 
                
                // LCR Update
                if(xtn_h.PADDR == 8'hC &&
                    xtn_h.PWRITE == 1)
                    //xtn_h.LCR = vif.apb_mon_cb.PWDATA; ==> We have data available in xtn
                    xtn_h.LCR = xtn_h.PWDATA;
                
                // IER Update
                if(xtn_h.PADDR == 8'h4 &&
                    xtn_h.PWRITE == 1)
                    xtn_h.IER = xtn_h.PWDATA;

                // FCR Update
                if(xtn_h.PADDR == 8'h8 &&
                    xtn_h.PWRITE == 1)
                    xtn_h.FCR = xtn_h.PWDATA;

                // IIR Update  ==> READ Only
                if(xtn_h.PADDR == 8'h8 &&
                    xtn_h.PWRITE == 0) 
                    begin 
                        //while(vif.apb_mon_cb.IRQ !== 1)
                        while(xtn_h.IRQ !== 1) // I already have IRQ sampled (Why do I need to use vif.cb here then ?)
                            @(vif.apb_mon_cb)
                            xtn_h.IIR = vif.apb_mon_cb.PRDATA;       
                    end
                
                // MCR Update 
                if(xtn_h.PADDR == 8'h10 &&
                    xtn_h.PWRITE == 1)
                    xtn_h.MCR = xtn_h.PWDATA;

                // LSR Read 
                if(xtn_h.PADDR == 8'h14 &&
                    xtn_h.PWRITE == 0)
                    //xtn_h.LSR = xtn_h.PWDATA; // Mam did directly ?? don't we need to check if iir is lsr or not ? 
                    begin
                        while(xtn_h.IIR !== 6)
                            @(vif.apb_mon_cb)
                        xtn_h.LSR = xtn_h.PRDATA;
                    end

                // DIV - LSB
                if(xtn_h.PADDR == 8'h1C &&
                    xtn_h.PWRITE == 1) 
                    begin : divisor_lsb

                        xtn_h.DIV[7:0] = xtn_h.PWDATA;
                        xtn_h.dl_access = 1;

                    end : divisor_lsb
                    
                // DIV - MSB
                if(xtn_h.PADDR == 8'h20 &&
                    xtn_h.PWRITE == 1)
                    begin : divisor_msb

                        xtn_h.DIV[15:8] = xtn_h.PWDATA;
                        xtn_h.dl_access = 1;

                    end : divisor_msb

                // THR 
                if(xtn_h.PADDR == 8'h0 &&
                    xtn_h.PWRITE == 1) 
                    begin : THR_REG

                        xtn_h.data_in_thr = 1;
                        xtn_h.THR.push_back(xtn_h.PWDATA);
                    end : THR_REG
                
                // RBR 
                if(xtn_h.PADDR == 8'h0 &&
                    xtn_h.PWRITE == 0) 
                    begin : RBR_REG

                        xtn_h.data_in_rbr = 1;
                        xtn_h.RBR.push_back(vif.apb_mon_cb.PRDATA);
                    end : RBR_REG

            end : transfer_capture

            // Send collected data to SB 
            mon_port.write(xtn_h);
    endtask 

endclass 

//-----------------------------------------------------UART MONITOR-------------------------------------------------------

class uart_mon extends uvm_monitor;
    `uvm_component_utils(uart_mon)

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 

endclass 


//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx AGENTS xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------APB AGENT-------------------------------------------------------

class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)

    apb_drv apb_drv_h; 
    apb_mon apb_mon_h; 
    apb_seqr apb_seqr_h; 

    apb_agent_config apb_cfg; 


    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

         if(!uvm_config_db #(apb_agent_config)::get(this,"","apb_agent_config",apb_cfg))
            `uvm_fatal(get_type_name(),"Failed to get() apb_cfg from ENV")

        apb_mon_h = apb_mon::type_id::create("apb_mon_h",this);

        if(apb_cfg.is_active == UVM_ACTIVE) begin 
            apb_drv_h = apb_drv::type_id::create("apb_drv_h",this);
            apb_seqr_h = apb_seqr::type_id::create("apb_seqr_h",this);
        end
    endfunction 

    function void connect_phase(uvm_phase phase);
        if(apb_cfg.is_active == UVM_ACTIVE) begin 
            apb_drv_h.seq_item_port.connect(apb_seqr_h.seq_item_export);
        end
    endfunction 
endclass 

//-----------------------------------------------------UART AGENT-------------------------------------------------------
class uart_agent extends uvm_agent;
    `uvm_component_utils(uart_agent)
    
    uart_drv uart_drv_h; 
    uart_mon uart_mon_h; 
    uart_seqr uart_seqr_h;

    uart_agent_config uart_cfg; 

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(uart_agent_config)::get(this,"","uart_agent_config",uart_cfg))
            `uvm_fatal(get_type_name(),"Failed to get() uart_cfg from ENV")

        uart_mon_h = uart_mon::type_id::create("uart_mon_h",this);

        if(uart_cfg.is_active == UVM_ACTIVE) begin   
            uart_drv_h = uart_drv::type_id::create("uart_drv_h",this);
            uart_seqr_h = uart_seqr::type_id::create("uart_seqr_h",this);
        end
    endfunction 

    function void connect_phase(uvm_phase phase);
        if(uart_cfg.is_active == UVM_ACTIVE) begin 
            uart_drv_h.seq_item_port.connect(uart_seqr_h.seq_item_export);
        end
    endfunction 
endclass 


//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx AGENT TOP xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------APB AGT TOP-------------------------------------------------------

class apb_agent_top extends uvm_agent; 
    `uvm_component_utils(apb_agent_top)

    apb_agent apb_agent_h;

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        apb_agent_h = apb_agent::type_id::create("apb_agent_h",this);
    endfunction 
endclass 

//-----------------------------------------------------UART AGT TOP-------------------------------------------------------
class uart_agent_top extends uvm_agent; 
    `uvm_component_utils(uart_agent_top)

    uart_agent uart_agent_h; 

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        uart_agent_h = uart_agent::type_id::create("uart_agent_h",this);
    endfunction 
endclass 

//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx SCOREBOARD xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//-----------------------------------------------------SB-------------------------------------------------------

class sb extends uvm_scoreboard; 
    `uvm_component_utils(sb)

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 


endclass 

//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ENV xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------ENV-------------------------------------------------------
class env extends uvm_env;
    `uvm_component_utils(env)

    apb_agent_top apb_agent_top_h; 
    uart_agent_top uart_agent_top_h;
    vseqr vseqrh;
    sb sb_h; 

    env_config env_cfg; 

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(env_config)::get(this,"","env_config",env_cfg))
            `uvm_fatal(get_type_name(),"Failed to get env_cfg from TEST")

        // set apb_cfg and create the apb agent top 
        if(env_cfg.has_apb_agent)
            begin 
                uvm_config_db #(apb_agent_config)::set(this,"*","apb_agent_config",env_cfg.apb_cfg);
                apb_agent_top_h = apb_agent_top::type_id::create("apb_agent_top_h",this);
            end


        // set uart_cfg and create the uart agent top 
        if(env_cfg.has_uart_agent)
            begin 
                uvm_config_db #(uart_agent_config)::set(this,"*","uart_agent_config",env_cfg.uart_cfg);
                uart_agent_top_h = uart_agent_top::type_id::create("uart_agent_top_h",this);
            end

        vseqrh = vseqr::type_id::create("vseqrh",this);
        sb_h = sb::type_id::create("sb_h",this);
    endfunction 
endclass 


//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx TEST xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------TEST-------------------------------------------------------\
class test extends uvm_test;
    `uvm_component_utils(test)

    env envh;
    vseq vseqh; 
    env_config env_cfg; 
    apb_agent_config apb_cfg; 
    uart_agent_config uart_cfg; 
    
    int has_apb_agent = 1; 
    //env_cfg.has_uart_agent = 1; // why this will throw error ?? 
    int has_uart_agent = 1; 

    function new(string name="",uvm_component parent);
        super.new(name,parent);
    endfunction 

    function void create_config();
        if(has_apb_agent)
            begin 
                apb_cfg = apb_agent_config::type_id::create("apb_cfg");

                if(!uvm_config_db #(virtual apb_if)::get(this,"","apb_if",apb_cfg.vif))
                    `uvm_fatal(get_type_name(),"Failed to get vif from TOP")
                
                apb_cfg.is_active = UVM_ACTIVE; 
                env_cfg.apb_cfg = apb_cfg; // handle assignment to apb agent inside env config
            end

        if(has_uart_agent)
             begin 
                uart_cfg = uart_agent_config::type_id::create("uart_cfg");

                // if(!uvm_config_db #(virtual uart_if)::get(this,"","uart_if",uart_cfg.vif))
                //     `uvm_fatal(get_type_name(),"Failed to get vif from TOP")
                
                uart_cfg.is_active = UVM_ACTIVE; 
                env_cfg.uart_cfg = uart_cfg; // handle assignment to apb agent inside env config
            end

        env_cfg.has_apb_agent = has_apb_agent; 
        env_cfg.has_uart_agent = has_uart_agent; 
    endfunction 


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env_cfg = env_config::type_id::create("env_cfg");

        // call config function 
        create_config();

        uvm_config_db #(env_config)::set(this,"*","env_config",env_cfg);


        vseqh = vseq::type_id::create("vseqh");
        envh = env::type_id::create("envh",this);
    endfunction 

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction 
endclass 


//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx TOP xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

//-----------------------------------------------------TOP-------------------------------------------------------
module uvm_uart_apb;
    bit clk1 = 0;
    bit clk2 = 0;
    bit PRESETn = 0; 
    // CLK 1 ==> 100 MHz freq --> 10ns TIme Period 
    always #5 clk1 = ~clk1; 

    // CLK 2 ==> 50 MHz freq --> 20ns TIme Period 
    always #10 clk2 = ~clk2; 

    // Initialization of RESET and CLK
    initial begin 
        clk1 = 0;
        clk2 = 0; 
        PRESETn = 0;
        #100; 
        PRESETn = 1;
    end

    // Instantiate interfaces 
    apb_if APB_IF(clk1); // APB interface for DUT
    // uart_if UART_IF();  // UART interface for VIP 

    // UART VIP Baud rate generator
    /*
    In DUT, baud rate is generated internally using the divisor register, but in the UART agent, 
    since it is a verification model without baud generation logic, 
    we generate the baud tick externally in the testbench to maintain correct timing for driving and sampling.
    */
    localparam int clk_freq  = 50000000;  // 50 MHz 
    localparam int BAUD_RATE = 115200;    // Target Baud rate 
    localparam int SAMPLE    = 16;        // Oversampling factor 

    // Baud rate divisor 
    localparam int DIVISOR = clk_freq / (BAUD_RATE * SAMPLE);

    int baud_cnt; // Count used for checking if baud tick happened (after 16 pulses of baud)

    // Generating Baud tick for UART VIP  ==> We did not write any logic for Baud tick in Sequence ?? 
    always_ff@(posedge clk2 or negedge PRESETn)
        if(!PRESETn) begin 
            baud_cnt       <= 0; 
            //UART_IF.baud_o <= 0;
        end
        else if(baud_cnt == DIVISOR - 1) begin 
            baud_cnt       <= 0;
            //UART_IF.baud_o <= 1; 
        end
        else begin 
            baud_cnt++;
            //UART_IF.baud_o <= 0; 
        end
/*
    // DUT Instantiation (UART)
    uart_16550(
        .PCLK    (clk1),
        .PRESETn (APB_IF.PRESETn),
        .PENABLE (APB_IF.PENABLE),
        .PWRITE  (APB_IF.PWRITE),
        .PADDR   (APB_IF.PADDR),
        .PRDATA  (APB_IF.PRDATA),
        .PWDATA  (APB_IF.PWDATA),
        .PSEL    (APB_IF.PSEL),
        .PREADY  (APB_IF.PREADY),
        .PSLVERR (APB_IF.PSLVERR),
        .IRQ     (APB_IF.IRQ),
        .TXD     (UART_IF.TxD), // DUT transmit to VIP receive
        .RXD     (UART_IF.RxD)  // VIP transmit to DUT receive 
    );
*/  

    initial begin 
        // Set virtual interfaces in UVM virtual db
        //uvm_config_db #(virtual uart_if)::set(null, "*", "uart_if", UART_IF);
        uvm_config_db #(virtual apb_if)::set(null, "*", "apb_if", APB_IF);
        run_test("test");
    end
endmodule 