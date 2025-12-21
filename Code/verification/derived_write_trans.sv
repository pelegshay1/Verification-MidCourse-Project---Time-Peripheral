//------------------------------------------------------------------------------
// CLASS: TimerWriteTransaction
// DESCRIPTION: Specializes the base class for WRITE operations.
//------------------------------------------------------------------------------
class TimerWriteTransaction extends TimerBaseTransaction;

    // FCN: new
    // DESCRIPTION: Constructor. Calls super.new() with the specific kind.
    function new();
        super.new(WRITE_OP); // Set kind = WRITE_OP
    endfunction : new

    // FCN: display (Override) - REMAINS THE SAME
    function void display(string i_tag = "WRITE-TRANS");
        $display("[%s] Type: %s, Addr: 0x%h, WDATA: 0x%h", 
                 i_tag, get_kind().name(), get_addr(), get_data());
    endfunction : display

endclass : TimerWriteTransaction