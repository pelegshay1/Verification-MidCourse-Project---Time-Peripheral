//------------------------------------------------------------------------------
// FILE: TimerGenerator.sv
// AUTHOR: Peleg
// DESCRIPTION: Creates random, constrained transactions and sends them
//              to the Driver via a mailbox.
//------------------------------------------------------------------------------

import design_params_pkg::*;

// Enum for Register Addresses (Copied from Checker for self-containment)
// typedef enum logic [P_ADDR_WIDTH-1:0] {
//     ADDR_CONTROL    = 8'h00,
//     ADDR_LOAD       = 8'h04,
//     ADDR_STATUS     = 8'h08,
//     ADDR_COUNT      = 8'h0C
// } RegAddr_e;


//------------------------------------------------------------------------------
// CLASS: TimerGenerator
// DESCRIPTION: Generates transactions and puts them into the Driver mailbox.
//------------------------------------------------------------------------------
class TimerGenerator;

    //--------------------------------------------------------------------------
    // Class Members
    //--------------------------------------------------------------------------
    // Mailbox to send transactions to the Driver
    mailbox #(TimerBaseTransaction) m_mbox;

    // Number of transactions to generate (local m_ prefix for internal state)
    local int m_num_trans;

    // FCN: new
    function new(mailbox #(TimerBaseTransaction) i_mbox, int i_num_trans = 10);
        m_mbox = i_mbox;
        m_num_trans = i_num_trans;
    endfunction : new

    //--------------------------------------------------------------------------
    // TASK: run
    // DESCRIPTION: Main loop to generate and send the specified number of transactions.
    //--------------------------------------------------------------------------
    task run();
        $display("[Generator] Starting to generate %0d transactions.", m_num_trans);

        for (int i = 0; i < m_num_trans; i++) begin
            TimerBaseTransaction tr;

            // 1. Decide Randomly whether to create a Read or a Write
            if ($urandom_range(0, 1)) begin
                // Create a WRITE transaction (50% chance)
                TimerWriteTransaction wr;
                wr = new();
                tr = wr;
            end else begin
                // Create a READ transaction (50% chance)
                TimerReadTransaction rd;
                rd = new();
                tr = rd;
            end

            // 2. Randomize and Constrain the Transaction Fields
            if (tr.randomize() with {
                    // Constrain the address to be one of the legal register addresses
                    tr.m_addr inside { ADDR_CONTROL, ADDR_LOAD, ADDR_STATUS, ADDR_COUNT };

                    if (tr.m_addr == ADDR_LOAD) {
                        tr.m_data  inside {[1:20]};
                    }


                    if (tr.m_addr == ADDR_CONTROL) {
                        tr.m_data [0] == 1'b1; // Assert Start bit to actually initiate the counter
                        tr.m_data [1] dist {0:=50, 1:=50}; // One Shot and Auto Reload Random 50/50 to get 100% coverage 
                    }

                    // If it's a WRITE transaction (Data is relevant only for writes here)
                    // Note: We need a specialized constraint on the derived class!
                    if (tr.get_kind() == WRITE_OP) {
                        // Example: Constrain data to be non-zero for control/load registers
                        tr.m_data > 0;
                    }
                }) begin
                $display("[%tns] Generator: Successfully randomized transaction #%0d.", $time, i);
                tr.display("GEN-OUT");
            end else begin
                $fatal(0, "Generator: Failed to randomize transaction!");
            end

            // 3. Send the randomized transaction to the Driver
            m_mbox.put(tr);

            // Optional: Add a small delay between transactions
            #5ns;
        end

        $display("[Generator] Finished generating transactions. Exiting.", $time);
    endtask : run

endclass : TimerGenerator