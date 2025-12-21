//------------------------------------------------------------------------------
// FILE: TimerDriver.sv
// AUTHOR: Peleg (Adapted to Native SV)
// DESCRIPTION: Implements the REQ/GNT bus protocol logic.
//              Receives TimerBaseTransaction objects from the Generator via Mailbox.
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// CLASS: TimerDriver (Standalone SystemVerilog Class)
//------------------------------------------------------------------------------
class TimerDriver;

    //--------------------------------------------------------------------------
    // Class Members (m_ prefix, local/public separation)
    //--------------------------------------------------------------------------
    // Virtual Interface Handle (local, as only the Driver uses the physical signals)
    virtual timer_if.DRIVER m_vif; 
    
    // Mailbox to receive transactions from the Generator (Public/Default, must be accessible)
    mailbox #(TimerBaseTransaction) m_mbox;

    //--------------------------------------------------------------------------
    // FCN: new (Simple Constructor)
    //--------------------------------------------------------------------------
    function new(virtual timer_if.DRIVER i_vif, mailbox #(TimerBaseTransaction) i_mbox);
        m_vif  = i_vif ; 
        m_mbox = i_mbox;                                                    
    endfunction : new

    //--------------------------------------------------------------------------
    // TASK: run (Main loop to process transactions from the Mailbox)
    //--------------------------------------------------------------------------
    task run();
        TimerBaseTransaction tr; // Generic pointer to the base class
        
        wait(m_vif.reset_n === 1'b1); // Wait for Startup-Reset

        @(posedge m_vif.clk);

        
        $display("[Driver] Starting bus driving loop at time %0t", $time);

        // --- Initialize Bus Signals to IDLE ---
        @(m_vif.driver_cb);
        m_vif.driver_cb.req       <= 1'b0;
        m_vif.driver_cb.write_en  <= 1'b0;
        m_vif.driver_cb.addr      <= '0;
        m_vif.driver_cb.wdata     <= '0;
        
        forever begin
            // 1. Wait for the next transaction item from the Generator (blocking call)
            m_mbox.get(tr);
            
            // 2. Execute the REQ/GNT protocol
            drive_transaction(tr);
            
            tr.display("DRV-DONE");
        end
    endtask : run

    //--------------------------------------------------------------------------
    // TASK: drive_transaction (Implements the strict REQ/GNT handshake timing)
    //--------------------------------------------------------------------------
    local task drive_transaction(TimerBaseTransaction i_tr);
        
        // Use $cast to safely access specific fields (Write Data / Read Data)
        TimerWriteTransaction write_tr;
        TimerReadTransaction  read_tr;
        
        i_tr.display("DRV-IN");

        // --- 1. REQUEST PHASE (Assert req and data) ---
        @(m_vif.driver_cb); 
        m_vif.driver_cb.req       <= 1'b1;
        m_vif.driver_cb.addr      <= i_tr.get_addr();
        
        if ($cast(write_tr, i_tr)) begin
            // Write Transaction: Drive WDATA and set write_en
            m_vif.driver_cb.write_en  <= 1'b1;
            m_vif.driver_cb.wdata     <= write_tr.get_data();
        end else if ($cast(read_tr, i_tr)) begin
            // Read Transaction: Clear write_en and drive wdata as 'X' or '0'
            m_vif.driver_cb.write_en  <= 1'b0;
            m_vif.driver_cb.wdata     <= '0; // Drive safe value
        end else begin
            $fatal(0, "Driver received an unhandled transaction type.");
        end

        // Wait one clock cycle (or more, depending on protocol setup)
        @(m_vif.driver_cb);
        
        // --- 2. HANDSHAKE PHASE (Wait for GNT) ---
        // The driver waits for the DUT to assert gnt.
        wait (m_vif.driver_cb.gnt);
        
        // --- 3. CAPTURE / READ PHASE (GNT is now high) ---
        if ($cast(read_tr, i_tr)) begin
            // Read: rdata is valid in the same cycle as GNT assertion
            read_tr.set_data(m_vif.driver_cb.rdata); 
        end
        
        // Wait one more cycle before de-asserting the request
        @(m_vif.driver_cb); 
        
        // --- 4. COMPLETION PHASE ---
        m_vif.driver_cb.req <= 1'b0;
        m_vif.driver_cb.write_en <= 1'b0; // Clean up
        m_vif.driver_cb.addr <= '0;      // Clean up

    endtask : drive_transaction
    
endclass : TimerDriver