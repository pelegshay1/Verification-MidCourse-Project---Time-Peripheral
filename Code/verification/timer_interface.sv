//------------------------------------------------------------------------------
// FILE: timer_if.sv
// AUTHOR: Peleg
// DESCRIPTION: Interface for the Timer Peripheral bus.
//              Includes clocking blocks for Driver and Monitor.
//------------------------------------------------------------------------------

`timescale 1ns/1ps

// Import the design parameters to ensure consistency (widths, etc.)
import design_params_pkg::*; 

interface timer_if (input logic clk, input logic reset_n);

    //--------------------------------------------------------------------------
    // Bus Signals (Parameterized)
    //--------------------------------------------------------------------------
    logic                      req;
    logic                      gnt;
    logic                      write_en;
    logic [P_ADDR_WIDTH-1:0]   addr;    // Using P_ADDR_WIDTH from params_pkg
    logic [P_DATA_WIDTH-1:0]   wdata;   // Using P_DATA_WIDTH from params_pkg
    logic [P_DATA_WIDTH-1:0]   rdata;   // Using P_DATA_WIDTH from params_pkg

    //--------------------------------------------------------------------------
    // Clocking Block: DRIVER
    // Used by the Driver to drive inputs and sample outputs synchronously.
    //--------------------------------------------------------------------------
    clocking driver_cb @(posedge clk);
        default input #1step output #1; // Input skew: 1step, Output skew: 1ns
        
        output req;
        output write_en;
        output addr;
        output wdata;
        input  gnt;
        input  rdata;
    endclocking

    //--------------------------------------------------------------------------
    // Clocking Block: MONITOR
    // Used by the Monitor to passively sample all bus signals.
    //--------------------------------------------------------------------------
    clocking monitor_cb @(posedge clk);
        default input #1step output #0;
        
        input req;
        input gnt;
        input write_en;
        input addr;
        input wdata;
        input rdata;
    endclocking

    //--------------------------------------------------------------------------
    // Modports
    //--------------------------------------------------------------------------
    modport DRIVER  (input clk,
        input reset_n,
        clocking driver_cb);
    modport MONITOR (clocking monitor_cb);

endinterface : timer_if