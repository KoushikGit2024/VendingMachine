// ============================================================================
// Module: refund_controller
// Description: Synchronous transaction cancellation refund controller for the
//              Digital Vending Machine controller.
// Standard: IEEE 1364-2001 (Verilog-2001)
// ============================================================================

`timescale 1ns / 1ps

module refund_controller #(
    parameter MONEY_WIDTH = 16
)(
    input  wire                   clk,
    input  wire                   rst,

    input  wire                   calc_refund_en,

    input  wire [MONEY_WIDTH-1:0] accum_balance,

    output reg  [MONEY_WIDTH-1:0] refund_amount,
    output reg                    refund_valid,
    output reg                    refund_done
);

    always @(posedge clk) begin
        if (rst) begin
            refund_amount <= {MONEY_WIDTH{1'b0}};
            refund_valid  <= 1'b0;
            refund_done   <= 1'b0;
        end else if (calc_refund_en) begin
            refund_amount <= accum_balance;
            refund_valid  <= 1'b1;
            refund_done   <= 1'b1;
        end else begin
            refund_valid  <= 1'b0;
            refund_done   <= 1'b0;
        end
    end

endmodule
