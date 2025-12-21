//------------------------------------------------------------------------------
// FILE: TimerChecker.sv
// AUTHOR: Peleg
// DESCRIPTION: The Scoreboard/Checker component. Receives transactions from
//              the Monitor and compares them against a Reference Model.
//------------------------------------------------------------------------------

import design_params_pkg::*; 

// Enum for Register Addresses (Temporary definition until RAL is ready)
// typedef enum logic [P_ADDR_WIDTH-1:0] {
//     ADDR_CONTROL    = 8'h00,
//     ADDR_LOAD       = 8'h04,
//     ADDR_STATUS     = 8'h08,
//     ADDR_COUNT      = 8'h0C
// } timer_reg_addr_e;

//------------------------------------------------------------------------------
// CLASS: TimerReferenceModel (Internal component of the Checker)
// DESCRIPTION: Simulates the internal state and behavior of the DUT registers.
//------------------------------------------------------------------------------
class TimerReferenceModel;
    
    // Internal state of the registers (local m_ prefix)
    local logic [P_DATA_WIDTH-1:0] m_ctrl_reg = '0;  //Control Register 
    local logic [P_DATA_WIDTH-1:0] m_load_reg = '0;  //Load Register
    local logic [P_DATA_WIDTH-1:0] m_status_reg = '0; //Status Register
    local logic [P_DATA_WIDTH-1:0] m_count_reg = '0; // Count Register

    // FCN: new (Constructor)
    function new(); endfunction

    // TASK: predict_write (Simulates a write operation effect)
    // ARGUMENTS:
    //   i_addr - The address being written to.
    //   i_wdata - The data being written.
    task predict_write(timer_reg_addr_e i_addr, logic [P_DATA_WIDTH-1:0] i_wdata);
        case (i_addr)
            ADDR_CONTROL: begin 
                m_ctrl_reg = i_wdata;
                $display("[RefModel] Wrote 0x%h to CONTROL", i_wdata);
            end
            ADDR_LOAD: begin
                m_load_reg = i_wdata;
                $display("[RefModel] Wrote 0x%h to LOAD", i_wdata);
            end
            // We do not allow writing to STATUS/COUNT in the model
            default: $warning("Write to unmapped address 0x%h", i_addr);
        endcase
    endtask

    // FCN: predict_read (Simulates a read operation and returns the expected data)
    // ARGUMENTS:
    //   i_addr - The address being read from.
    //   o_rdata - Output for the expected read data.
    function logic [P_DATA_WIDTH-1:0] predict_read(timer_reg_addr_e i_addr);
        case (i_addr)
            ADDR_CONTROL: return m_ctrl_reg;
            ADDR_LOAD: return m_load_reg;
            ADDR_STATUS: begin
                // Example of complex behavior: STATUS is Read-Clear
                logic [P_DATA_WIDTH-1:0] read_val = m_status_reg;
                m_status_reg = '0; // Clear after reading
                $display("[RefModel] Read STATUS (0x%h) and Cleared.", read_val);
                return read_val;
            end
            ADDR_COUNT: return m_count_reg;
            default: begin 
                $warning("Read from unmapped address 0x%h", i_addr); 
                return '0;
            end
        endcase
    endfunction


// local bit m_timer_running = 1'b0; // Internal Flag

// // TASK: start_timer (Counter Modeling)
// task start_timer();
//     m_count_reg = m_load_reg; // Load Value
//     m_timer_running = 1'b1;
    
//     fork
//         decrement_count();
//     join_none
// endtask

// // TASK: decrement_count (מטפל בספירה עצמה)
// local task decrement_count();
//     $display("[RefModel] Timer started counting from %0d", m_count_reg);
    
//     // Loop Counter Sync. with System CLK
//     while (m_timer_running && m_count_reg > 0) begin
//         @(posedge clk); // 
//         m_count_reg--;
//         $display("[RefModel] Count: %0d", m_count_reg);
//     end
    
//     // Finished Counting
//     if (m_count_reg == 0) begin
//         m_timer_running = 1'b0;
//         m_status_reg |= EXPIRED_BIT; // Define Finished flag
//         $display("[RefModel] Timer expired!");
//     end
// endtask

    
endclass : TimerReferenceModel
//------------------------------------------------------------------------------
// CLASS: TimerChecker (Scoreboard)
//------------------------------------------------------------------------------
class TimerChecker;
    
    // Class Members (m_ prefix, local)
    mailbox #(TimerBaseTransaction) m_mbox;
    local TimerReferenceModel           m_ref_model; // Reference Model object
    local int                           m_count;
    local int                           m_limit = 20; // Example limit
    
    // FCN: new
    // DESCRIPTION: Constructor for the TimerChecker.
    // ARGUMENTS:
    //   i_mbox - Mailbox handle to receive transactions from the Monitor.
    function new (mailbox #(TimerBaseTransaction) i_mbox);
        m_mbox = i_mbox;
        m_ref_model = new(); // Initialize the internal Reference Model
    endfunction : new 

    // TASK: run
    // DESCRIPTION: Main loop to process transactions and compare them.
    task run();
        TimerBaseTransaction tr; // Generic pointer to the base class
        
        $display("[Checker] Starting run phase at time %0t", $time);
        
        forever 
        begin
            // 1. Get the next transaction from the Monitor (blocking call)
            m_mbox.get(tr);
            
            // 2. Process and Compare the observed transaction
            process_transaction(tr);
            
            m_count++;
            if (m_count >= m_limit) begin
                $display("Checker: Processed %0d transactions. Reached limit. Exiting.", m_count);
                // Note: In real UVM, this would raise a flag to end the test.
                return;
            end
        end
    endtask : run

    // TASK: process_transaction
    // DESCRIPTION: Uses the transaction kind to predict/check expected results.
    // ARGUMENTS:
    //   i_tr - The observed transaction from the Monitor.
    local task process_transaction(TimerBaseTransaction i_tr);
        
        // Use Polymorphism and $cast to identify the exact type
        TimerWriteTransaction write_tr;
        TimerReadTransaction  read_tr;
        
        i_tr.display("CHK-IN"); // Call the correct display() method (Polymorphism)

        if ($cast(write_tr, i_tr)) begin
            // --- WRITE OPERATION ---
            m_ref_model.predict_write(timer_reg_addr_e'(write_tr.get_addr()), write_tr.get_data());
            // No explicit comparison for writes, only prediction/update of ref model state.
            
        end else if ($cast(read_tr, i_tr)) begin
            // --- READ OPERATION ---
            logic [P_DATA_WIDTH-1:0] expected_rdata;
            logic [P_DATA_WIDTH-1:0] actual_rdata = read_tr.get_data();
            
            // 1. Predict the expected result based on the model's current state
            expected_rdata = m_ref_model.predict_read(timer_reg_addr_e'(read_tr.get_addr()));
            
            // 2. Comparison and Mismatch Reporting
            if (expected_rdata == actual_rdata) begin
                $display("[Checker] SUCCESS: Read 0x%h from ADDR 0x%h. Expected=Actual.", 
                         actual_rdata, read_tr.get_addr());
            end else begin
                $error("[Checker] MISMATCH: Read ADDR 0x%h. Expected 0x%h, Got 0x%h.",
                       read_tr.get_addr(), expected_rdata, actual_rdata);
            end

        end else begin
            $fatal(0, "Checker received an unhandled transaction type.");
        end

    endtask : process_transaction

endclass : TimerChecker