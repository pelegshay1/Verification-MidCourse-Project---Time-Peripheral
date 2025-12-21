//------------------------------------------------------------------------------
// FILE: TimerCoverage.sv
// DESCRIPTION: Full implementation of Phase 4 Coverage Plan.
//------------------------------------------------------------------------------
class TimerCoverage;



// --- Covergroup Definition ---
// Includes all coverpoints and crosses for the Timer Periphera
covergroup cg_timer_all;
        option.per_instance = 1; // Track coverage for each instance of this class

        // --- 1. Timer Configuration & Commands ---

        // Coverage for different values loaded into the timer (LOAD register)
        cp_load_val: coverpoint tr.get_data() 
        iff (tr.get_kind() == WRITE_OP && tr.get_addr() == 8'h04) {
            bins b_zero   = { 0 };
            bins b_small  = { [1:10] };
            bins b_mid    = { [11:1000] };
            bins b_max    = { 65535 };
        }

        // Coverage for the start trigger bit in the CONTROL register
        cp_start: coverpoint tr.get_data()[0] 
        iff (tr.get_kind() == WRITE_OP && tr.get_addr() == 8'h00) {
            bins start_trigger = { 1 };
        }

        // Coverage for various methods of clearing the status interrupt flag
        cp_flag_clear: coverpoint tr.get_kind() {
            bins read_clear  = { READ_OP } iff (tr.get_addr() == 8'h08);
            bins write_clear = { WRITE_OP } iff (tr.get_addr() == 8'h08 && tr.get_data()[0] == 1);
        }

        // --- 2. Timer-State & Operational Modes ---

        // Coverage for Timer Mode: One-Shot (0) vs. Auto-Reload (1)
        cp_reload_en: coverpoint tr.get_data()[1] 
        iff (tr.get_kind() == WRITE_OP && tr.get_addr() == 8'h00) {
            bins one_shot    = { 0 };
            bins auto_reload = { 1 };
        }

        // Coverage for the transition of the expired flag from 0 to 1
        cp_expired_status: coverpoint tr.get_data()[0] 
        iff (tr.get_addr() == 8'h08) {
            bins expired_event = (0 => 1); 
        }

        // --- 3. Cross Coverage 
        // Verifies that both One-Shot and Auto-Reload modes were tested with various LOAD values
        cross_mode_and_load:  cross cp_reload_en, cp_load_val;

        // Verifies that the flag was cleared correctly in both operational modes
        cross_mode_and_clear: cross cp_reload_en, cp_flag_clear;
        
    endgroup

    // Member variable to hold the transaction being sampled
    TimerBaseTransaction tr;

    // Constructor: Initializes the covergroup
    function new();
        cg_timer_all = new();
    endfunction

    task sample(TimerBaseTransaction tr); // Samples the transactions into the coverage collector

        this.tr = tr;

        $display("[%t] Coverage: Sampling transaction Type: %s, Addr: 0x%h, Data: 0x%h", 
              $time, 
              tr.get_kind().name(), 
              tr.get_addr(),       
              tr.get_data()        
    );
        
        cg_timer_all.sample();
    endtask : sample
endclass

