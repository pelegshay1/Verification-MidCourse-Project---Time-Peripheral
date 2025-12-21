//------------------------------------------------------------------------------
// FILE: tb_top.sv
// AUTHOR: Peleg
// DESCRIPTION: Top level module for the Timer Verification Testbench.
//              Handles clock/reset generation, interface, DUT, and test class.
//------------------------------------------------------------------------------
 
`timescale 1ns / 1ps

module tb_top;
    
    // --- 1. Clock and Reset Generation (Step 1) ---
    parameter CLK_PERIOD = 10ns;
    logic clk;
    logic rst_n; // Active low reset
    
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    initial begin
        rst_n = 1'b0;
        #20ns; // Hold reset low for a brief period
        rst_n = 1'b1;
        $display("[%t] Reset released.", $time);
    end

    // --- 2. Interface Instance (Step 2) ---
    timer_if timer_bus_if(.clk(clk), .reset_n(rst_n));

    // --- 3. DUT Instance (connected via SLAVE modport) ---
    // Note: The DUT is assumed to be defined externally.
    // For this example, let's assume the DUT needs a clock and the SLAVE modport.
    // If your DUT uses a direct connection, adjust here.
    wire expired_wire, counter_wire;

    timer_periph dut_inst (
        .clk     (clk),
        .reset_n (rst_n),
        .req     (timer_bus_if.req),
        .gnt     (timer_bus_if.gnt),
        .addr    (timer_bus_if.addr),
        .wdata   (timer_bus_if.wdata),
        .rdata   (timer_bus_if.rdata),
        .write_en(timer_bus_if.write_en),
        

        .debug_expired(expired_wire), 
        .debug_counter(counter_wire)
    );

    timer_assertions my_assertions (
        .clk(clk),
        .rst_n(rst_n),
        .req(timer_bus_if.req),
        .gnt(timer_bus_if.gnt),
        .write_en(timer_bus_if.write_en),
        .addr(timer_bus_if.addr),
        .wdata(timer_bus_if.wdata),
        .expired_flag (expired_wire),
        .internal_count(counter_wire)
    );

    // --- 4. Test Class Instantiation and Execution ---
    TimerTest test_inst;
    
    initial begin
        //Contruct timertest object with 2 mailboxes.
        test_inst = new();
        
        // Connect the VIF handles to the Test Class, And start build_agent task to build all verification components
        test_inst.build_agent(timer_bus_if.DRIVER,  // VIF for Driver
                              timer_bus_if.MONITOR); // VIF for Monitor
        
        // Run the test logic
        test_inst.run_test();
        
        // Final control: Wait for the run_test to complete, then finish simulation
        wait(test_inst.m_gen.m_mbox.num() == 0 && test_inst.m_driver_mbox.num() == 0); 
        
        $finish; // Stop simulation (Step 1)
    end

endmodule