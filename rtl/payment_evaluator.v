// ============================================================================
// Module: payment_evaluator
// Description: Pure combinational payment comparison logic for the Digital
//              Vending Machine controller.
// Standard: IEEE 1364-2001 (Verilog-2001)
// ============================================================================

`timescale 1ns / 1ps

module payment_evaluator #(
    parameter MONEY_WIDTH = 16
)(
    input  wire [MONEY_WIDTH-1:0] accum_balance,
    input  wire [MONEY_WIDTH-1:0] prod_price,

    output wire                   payment_sufficient,
    output wire                   payment_exact,
    output wire                   payment_over,
    output wire                   payment_under
);

    assign payment_sufficient = (accum_balance >= prod_price);
    assign payment_exact      = (accum_balance == prod_price);
    assign payment_over       = (accum_balance > prod_price);
    assign payment_under      = (accum_balance < prod_price);

endmodule
