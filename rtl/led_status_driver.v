// ============================================================================
// Module: led_status_driver
// Description: Maps core vending machine status flags, state encodings,
//              inventory flags, and admin status to 16 FPGA evaluation board LEDs.
// Standard: IEEE 1364-2001 (Verilog-2001)
// ============================================================================

`timescale 1ns / 1ps

module led_status_driver (
    input  wire        ready,
    input  wire        busy,
    input  wire [3:0]  fsm_state,
    input  wire        dispense_valid,
    input  wire [1:0]  dispense_prod_id,
    input  wire        change_valid,
    input  wire        refund_valid,
    input  wire        online_pay_req,
    input  wire        coin_reject,
    input  wire        error_invalid_prod,
    input  wire        error_out_of_stock,
    input  wire        low_stock,
    input  wire        admin_mode_active,

    output wire [15:0] led
);

    assign led[0]     = ready;
    assign led[1]     = busy;
    assign led[2]     = dispense_valid;
    assign led[3]     = change_valid;
    assign led[4]     = refund_valid;
    assign led[5]     = online_pay_req;
    assign led[6]     = coin_reject;
    assign led[7]     = error_invalid_prod;
    assign led[8]     = error_out_of_stock;
    assign led[9]     = low_stock;
    assign led[10]    = admin_mode_active;
    assign led[11]    = 1'b0;
    assign led[15:12] = fsm_state;

endmodule
