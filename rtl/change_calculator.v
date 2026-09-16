// ============================================================================
// Module: change_calculator
// Description: Synchronous overpayment change calculator for the Digital
//              Vending Machine controller.
// Standard: IEEE 1364-2001 (Verilog-2001)
// ============================================================================

`timescale 1ns / 1ps

module change_calculator #(
    parameter MONEY_WIDTH = 16
)(
    input  wire                   clk,
    input  wire                   rst,

    input  wire                   calc_change_en,

    input  wire [MONEY_WIDTH-1:0] accum_balance,
    input  wire [MONEY_WIDTH-1:0] prod_price,

    output reg  [MONEY_WIDTH-1:0] change_amount,
    output reg                    change_valid,
    output reg                    change_done
);

    always @(posedge clk) begin
        if (rst) begin
            change_amount <= {MONEY_WIDTH{1'b0}};
            change_valid  <= 1'b0;
            change_done   <= 1'b0;
        end else if (calc_change_en) begin
            if (accum_balance >= prod_price) begin
                change_amount <= accum_balance - prod_price;
            end else begin
                change_amount <= {MONEY_WIDTH{1'b0}};
            end
            change_valid <= 1'b1;
            change_done  <= 1'b1;
        end else begin
            change_valid <= 1'b0;
            change_done  <= 1'b0;
        end
    end

endmodule
