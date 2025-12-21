//------------------------------------------------------------------------------
// FILE: TimerTest.sv
// AUTHOR: Peleg
// DESCRIPTION: Test class responsible for creating and connecting all
//              verification components (Generator, Driver, Monitor, Checker).
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// CLASS: TimerTest
// DESCRIPTION: Acts as the top-level environment for the Testbench.
//------------------------------------------------------------------------------
class TimerTest;

    //--------------------------------------------------------------------------
    // Class Members (The Verification Agent Components)
    //--------------------------------------------------------------------------
    TimerGenerator    m_gen;
    local TimerDriver       m_drv;
    local TimerMonitor      m_mon;
    local TimerChecker      m_chk;
    local TimerCoverage     m_cvr;
    
    // Mailboxes for TLM communication (Public/Default - shared links)
    mailbox #(TimerBaseTransaction) m_driver_mbox; // Gen -> Drv
    mailbox #(TimerBaseTransaction) m_checker_mbox; // Mon -> Chk

    // FCN: new (Constructor)
    function new();
        // 1. Create the Mailboxes
        m_driver_mbox  = new(10); // Queue size 10 (Gen -> Drv)
        m_checker_mbox = new(10); // Queue size 10 (Mon -> Chk)
    endfunction : new 

    //--------------------------------------------------------------------------
    // TASK: build_agent
    // DESCRIPTION: Creates the verification components and connects the mailboxes.
    // ARGUMENTS:
    //   i_vif_drv - VIF handle for the Driver
    //   i_vif_mon - VIF handle for the Monitor
    //--------------------------------------------------------------------------
    task build_agent(virtual timer_if.DRIVER i_vif_drv, 
                     virtual timer_if.MONITOR i_vif_mon);
        
        $display("[Test] Building Verification Agent Components...");

        // 2. Create the components, injecting the VIFs and Mailboxes
        
        // Generator: Needs the Driver Mailbox, needs to generate 20 transactions
        m_gen = new(m_driver_mbox, 100); 

        // Driver: Needs its VIF and the Driver Mailbox (Input)
        m_drv = new(i_vif_drv, m_driver_mbox);

        // Coverage Collector: Needs no arg. but - needs to be constructed before monitor
        m_cvr = new();

        // Monitor: Needs its VIF and the Checker Mailbox (Output)
        m_mon = new(i_vif_mon, m_checker_mbox, m_cvr);

        // Checker: Needs the Checker Mailbox (Input)
        m_chk = new(m_checker_mbox);

        
        $display("[Test] Verification Agent successfully built.");
    endtask : build_agent

    //--------------------------------------------------------------------------
    // TASK: run_test
    // DESCRIPTION: Runs all the components concurrently (in parallel).
    //--------------------------------------------------------------------------
    task run_test();
        // Runs all major components in parallel (Driver, Monitor, Checker, Generator)
        // This addresses Challenge 1 from Step 3: all components run concurrently.
        fork
            m_gen.run(); 
            m_drv.run();
            m_mon.run();
            m_chk.run();
        join_any // Wait for ANY component to finish (in our case, the Generator)
        
        // Wait for all remaining components to finish gracefully
        wait_for_finish(); 
        
    endtask : run_test
    
    //--------------------------------------------------------------------------
    // TASK: wait_for_finish
    // DESCRIPTION: Waits a few clocks to ensure all processes (Monitor/Checker) 
    //              have a chance to process final transactions.
    //--------------------------------------------------------------------------
    local task wait_for_finish();
        repeat(5) @(m_drv.m_vif.driver_cb); // Wait 5 clock cycles
        $display("[Test] All components finished. Simulation time: %0t", $time);
    endtask : wait_for_finish

endclass : TimerTest