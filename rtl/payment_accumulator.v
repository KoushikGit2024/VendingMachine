// ============================================================================
// Module: payment_accumulator
// Description: Synchronous balance accumulator with overflow protection for
//              the Digital Vending Machine controller.
// Standard: IEEE 1364-2001 (Verilog-2001)
// ============================================================================

`timescale 1ns / 1ps

module payment_accumulator #(
    parameter MONEY_WIDTH   = 16,
    parameter MAX_MONEY_CAP = 65535
)(
    input  wire                   clk,
    input  wire                   rst,

    input  wire [MONEY_WIDTH-1:0] coin_value,
    input  wire                   coin_accepted,
    input  wire                   accum_enable,
    input  wire                   accum_clear,

    output reg  [MONEY_WIDTH-1:0] accum_balance,
    output wire                   accum_is_zero,
    output reg                    accum_overflow
);

    assign accum_is_zero = (accum_balance == {MONEY_WIDTH{1'b0}});

    always @(posedge clk) begin
        if (rst) begin
            accum_balance  <= {MONEY_WIDTH{1'b0}};
            accum_overflow <= 1'b0;
        end else if (accum_clear) begin
            accum_balance  <= {MONEY_WIDTH{1'b0}};
            accum_overflow <= 1'b0;
        end else if (coin_accepted && accum_enable) begin
            // Check overflow using 17-bit intermediate sum
            if (({1'b0, accum_balance} + {1'b0, coin_value}) > MAX_MONEY_CAP) begin
                accum_overflow <= 1'b1;
                // accum_balance retained without corruption
            end else begin
                accum_balance  <= accum_balance + coin_value;
                accum_overflow <= 1'b0;
            end
        end else begin
            accum_overflow <= 1'b0;
        end
    end

endmodule
