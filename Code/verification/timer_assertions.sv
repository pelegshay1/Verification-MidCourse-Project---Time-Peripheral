module timer_assertions (
    input logic clk,
    input logic rst_n,
    input logic req,
    input logic gnt,
    input logic write_en,
    input logic [7:0] addr,
    input logic [7:0] wdata,
    input logic expired_flag,      
    input logic [15:0] internal_count 
);

    //--------------------------------------------------------------------------
    // 1. Request Timeout (Step 7)
    // REQ not high for more than 3 cycles without GNT response
    //--------------------------------------------------------------------------
    property p_req_timeout;
        @(posedge clk) disable iff (!rst_n)
        req |-> ##[0:3] gnt; 
    endproperty

    a_req_timeout: assert property (p_req_timeout)
        else $error("Assertion Failed: REQ stayed high for >3 cycles without GNT!"); //[cite: 123, 125]

    //--------------------------------------------------------------------------
    // 2. Expiration Logic (Step 7)
    // Expired flag only asserted when counter reaches zero
    //--------------------------------------------------------------------------
    property p_expiration_logic;
        @(posedge clk) disable iff (!rst_n)
        $rose(expired_flag) |-> (internal_count == 0);
    endproperty

    a_expiration_logic: assert property (p_expiration_logic)
        else $error("Assertion Failed: Expired flag asserted but counter is not zero!"); //[cite: 124, 126]

    //--------------------------------------------------------------------------
    // 3. Status Clear (Step 7)
    // CLR_STATUS clears expired flag within <=1 cycle
    //--------------------------------------------------------------------------
    property p_status_clear;
        @(posedge clk) disable iff (!rst_n)
        (req && gnt && write_en && (addr == 8'h08) && wdata[0]) |=> !expired_flag;
    endproperty

    a_status_clear: assert property (p_status_clear)
        else $error("Assertion Failed: Status flag not cleared after CLR_STATUS command!");// [cite: 131, 132]

endmodule