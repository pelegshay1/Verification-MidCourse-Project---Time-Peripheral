//------------------------------------------------------------------------------
// CLASS: TimerReadTransaction
// DESCRIPTION: Specializes the base class for READ operations.
//------------------------------------------------------------------------------
class TimerReadTransaction extends TimerBaseTransaction;

    // FCN: new
    // DESCRIPTION: Constructor. Calls super.new() with READ_OP.
    function new();
        super.new(READ_OP); // Set kind = READ_OP [cite: 29]
    endfunction : new

    // FCN: display (Override)
    function void display(string i_tag = "READ-TRANS");
        $display("[%s] Type: %s, Addr: 0x%h, RDATA: 0x%h", 
                 i_tag, get_kind().name(), get_addr(), get_data());
    endfunction : display

endclass : TimerReadTransaction