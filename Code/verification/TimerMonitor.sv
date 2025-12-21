//------------------------------------------------------------------------------
// FILE: TimerMonitor.sv
// AUTHOR: Peleg
// DESCRIPTION: Passive component that observes the bus, samples transactions,
//              and sends them to the Checker/Scoreboard via a mailbox.
//------------------------------------------------------------------------------

import design_params_pkg::*; // Import widths from the design package

//------------------------------------------------------------------------------
// CLASS: TimerMonitor (PascalCase)
// DESCRIPTION: Translates physical bus activity (REQ/GNT) into TLM objects.
//------------------------------------------------------------------------------
class TimerMonitor;
    
    //--------------------------------------------------------------------------
    // Class Members (m_ prefix, local)
    //--------------------------------------------------------------------------
    // Virtual interface handle with MONITOR modport
    local virtual timer_if.MONITOR m_vif;   
    
    // Mailbox to send sampled transactions to the Checker/Scoreboard
    mailbox #(TimerBaseTransaction) m_mbox;

    //Covergae Collector
    TimerCoverage m_cov;

    //--------------------------------------------------------------------------
    // FCN: new
    // DESCRIPTION: Constructor for TimerMonitor object 
    // ARGUMENTS:
    //   i_vif  - Virtual interface handle for the MONITOR modport.
    //   i_mbox - Mailbox handle to send sampled transactions.
    //--------------------------------------------------------------------------
    function new(virtual timer_if.MONITOR i_vif, mailbox #(TimerBaseTransaction) i_mbox,TimerCoverage i_cov );
        m_vif  = i_vif ; 
        m_mbox = i_mbox; 
        m_cov  = i_cov;													
    endfunction : new

    //--------------------------------------------------------------------------
    // TASK: run
    // DESCRIPTION: Main loop to continuously observe the bus for activity.
    //--------------------------------------------------------------------------
    task run();
        $display("[Monitor] Starting bus observation at time %0t", $time);
        
        forever 
        begin
            // Wait for the start of a transaction (REQ asserted)
            @(m_vif.monitor_cb); 
            wait (m_vif.monitor_cb.req == 1'b1);
            
            // Collect the full transaction details
            collect_transaction();
        end
    endtask : run

    //--------------------------------------------------------------------------
    // TASK: collect_transaction
    // DESCRIPTION: Samples the bus activity for one REQ/GNT cycle,
    //              creates the appropriate derived transaction object, and sends it.
    //--------------------------------------------------------------------------
    local task collect_transaction();
        TimerBaseTransaction tr; // Base Class handle
        
        // 1. Capture initial request signals from virtual interface on the cycle REQ is asserted 
        logic [P_ADDR_WIDTH-1:0] sampled_addr   = m_vif.monitor_cb.addr;
        bit                      sampled_write_en = m_vif.monitor_cb.write_en;
        logic [P_DATA_WIDTH-1:0] sampled_wdata  = m_vif.monitor_cb.wdata;
        
        // 2. Wait for GNT (Handshake phase)
        // Note: We wait until GNT is asserted, which can take several cycles
        wait (m_vif.monitor_cb.gnt == 1'b1);
        
        // 3. Create the appropriate derived transaction object
        if (sampled_write_en) 
        begin
            // Create a WRITE object
            TimerWriteTransaction wr_tr;
            wr_tr = new();
            tr = wr_tr;
            tr.set_data(sampled_wdata); // Set WDATA
        end 
        else 
        begin
            // Create a READ object
            TimerReadTransaction rd_tr;
            rd_tr = new();
            tr = rd_tr;
            
            // Read data is valid in the cycle GNT is asserted
            tr.set_data(m_vif.monitor_cb.rdata); // Capture RDATA
        end
        
        // 4. Set common fields (Addr)
        tr.set_addr(sampled_addr);
        
        // 5. Wait for transaction completion (REQ drops)
        @(m_vif.monitor_cb);
        wait (m_vif.monitor_cb.req == 1'b0);
        
        // 6. Send the sampled object to the mailbox towards Checker
        m_mbox.put(tr);

        //7. Send the object to the coverage collector
        m_cov.sample(tr);

        $display("[%tns] Monitor: Sent transaction to Scoreboard.", $time);
        tr.display("MON-OUT");
        
    endtask : collect_transaction
    
endclass : TimerMonitor