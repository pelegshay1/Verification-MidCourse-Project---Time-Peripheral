//------------------------------------------------------------------------------
// FILE: TimerBaseTransaction.sv
// DESCRIPTION: Base class for all Timer Peripheral bus transactions.
//------------------------------------------------------------------------------


import design_params_pkg::*;

// Enum definition for bus operation kind
typedef enum logic [1:0] {
    READ_OP,
    WRITE_OP,
    IDLE_OP
} BusOpKind_e;

//------------------------------------------------------------------------------
// CLASS: TimerBaseTransaction
// DESCRIPTION: Defines common fields (address, data, and kind).
//------------------------------------------------------------------------------
class TimerBaseTransaction;

    //--------------------------------------------------------------------------
    // Class Members (m_ prefix, local)
    //--------------------------------------------------------------------------
    rand logic [P_ADDR_WIDTH-1:0]  m_addr;
    rand logic [P_DATA_WIDTH-1:0]  m_data;

    // The 'kind' variable, now included per user request
    local BusOpKind_e               m_kind;

    //--------------------------------------------------------------------------
    // FCN: new
    // DESCRIPTION: Constructor. Initializes kind to a safe default.
    // ARGUMENTS:
    //   i_kind - The specific operation type (set by the derived class).
    //--------------------------------------------------------------------------
    function new(BusOpKind_e i_kind = IDLE_OP);
        m_kind = i_kind;
    endfunction : new

    //--------------------------------------------------------------------------
    // FCN: display (Polymorphic Method) - REMAINS VIRTUAL!
    // DESCRIPTION: Virtual function allowing derived classes to specialize
    //              their print format.
    //--------------------------------------------------------------------------
   virtual function void display(string i_tag = "TRANS");
        $display("[%s] Type: %s, Addr: 0x%h, Data: 0x%h",
            i_tag, m_kind.name(), m_addr, m_data);
    endfunction : display

    // --- Getters / Setters (Common) ---
    function BusOpKind_e get_kind();
        return m_kind;
    endfunction : get_kind

    // [Other getters/setters remain the same]
    function void set_addr(input logic [P_ADDR_WIDTH-1:0] i_addr);
        m_addr = i_addr;
    endfunction

    function logic [P_ADDR_WIDTH-1:0] get_addr();
        return m_addr;
    endfunction

    function void set_data(input logic [P_DATA_WIDTH-1:0] i_data);
        m_data = i_data;
    endfunction

    function logic [P_DATA_WIDTH-1:0] get_data();
        return m_data;
    endfunction

endclass : TimerBaseTransaction
