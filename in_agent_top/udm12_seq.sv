
// sequence -----------------------------------------------------------------------------------------

class seq_base extends uvm_sequence #(xtn);

    `uvm_object_utils(seq_base)

    function new(string name = "seq_base");
        super.new(name);
    endfunction

endclass 

// reset sequence
class seq_rstn extends seq_base;
    `uvm_object_utils(seq_rstn)

    function new(string name = "seq_rstn");
        super.new(name);
    endfunction

    task body();
        m_sequencer.grab(this);
        repeat(1) begin
            req = xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {rstn == 0;});
            finish_item(req);
        end
        m_sequencer.ungrab(this);
    endtask
endclass 

// load 1 - data in sequence
class seq_load extends seq_base;
    `uvm_object_utils(seq_load)

    function new(string name = "seq_load");
        super.new(name);
    endfunction

    task body();
        m_sequencer.lock(this);
        repeat(20) begin
            req = xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {rstn == 1 && load == 1;});
            finish_item(req);
        end
        m_sequencer.unlock(this);
    endtask
endclass 

// mode 1 - Upcount sequence 
class seq_md1 extends seq_base;
    `uvm_object_utils(seq_md1)

    function new(string name = "seq_md1");
        super.new(name);
    endfunction

    task body();
        m_sequencer.grab(this);
        repeat(20) begin
            req = xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {rstn == 1 && load == 0 && mode == 1;});
            finish_item(req);
        end
        m_sequencer.ungrab(this);
    endtask
endclass 

// mode 0 - Downcount sequence 
class seq_md0 extends seq_base;
    `uvm_object_utils(seq_md0)

    function new(string name = "seq_md0");
        super.new(name);
    endfunction

    task body();
        m_sequencer.grab(this);
        repeat(20) begin
            req = xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {rstn == 1 && load == 0 && mode == 0;});
            finish_item(req);
        end
        m_sequencer.ungrab(this);
    endtask
endclass 
