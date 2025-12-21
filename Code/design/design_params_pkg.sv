package design_params_pkg;
  parameter int P_ADDR_WIDTH = 8;
  parameter int P_DATA_WIDTH = 32;

  localparam logic [P_ADDR_WIDTH-1:0] P_ADDR_CONTROL = 'h00;
  localparam logic [P_ADDR_WIDTH-1:0] P_ADDR_LOAD    = 'h04;
  localparam logic [P_ADDR_WIDTH-1:0] P_ADDR_STATUS  = 'h08;

  localparam int P_BIT_START      = 0;
  localparam int P_BIT_RELOAD_EN  = 1;
  localparam int P_BIT_CLR_STATUS = 2;

  typedef enum logic [7:0] {
        ADDR_CONTROL = 8'h00,
        ADDR_LOAD    = 8'h04,
        ADDR_STATUS  = 8'h08,
        ADDR_COUNT   = 8'h0C
    } timer_reg_addr_e;
endpackage
