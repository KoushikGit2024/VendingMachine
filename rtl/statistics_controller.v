// ============================================================================
// Module: statistics_controller
// Description: Central transaction statistics counter module for Digital
//              Vending Machine. Tracks vends, cancellations, invalid coins,
//              online payments, cash payments, and total revenue.
// Standard: IEEE 1364-2001 (Verilog-2001)
// ============================================================================

`timescale 1ns / 1ps

module statistics_controller #(
    parameter MONEY_WIDTH   = 16,
    parameter COUNTER_WIDTH = 16
)(
    input  wire                   clk,
    input  wire                   rst,

    input  wire                   dispense_start,      // 1-cycle strobe on successful vend
    input  wire                   calc_refund_en,      // 1-cycle strobe on cancellation refund
    input  wire                   coin_reject_strobe,  // 1-cycle strobe on rejected/invalid coin
    input  wire                   online_paid_flag,    // 1 if current transaction was online
    input  wire                   online_pay_approved, // 1-cycle strobe when online payment approved
    input  wire [MONEY_WIDTH-1:0] vend_price,          // Price of dispensed product

    output reg  [COUNTER_WIDTH-1:0] total_transactions,
    output reg  [COUNTER_WIDTH-1:0] successful_vends,
    output reg  [COUNTER_WIDTH-1:0] cancelled_transactions,
    output reg  [COUNTER_WIDTH-1:0] invalid_coin_count,
    output reg  [COUNTER_WIDTH-1:0] online_payment_count,
    output reg  [COUNTER_WIDTH-1:0] cash_transaction_count,
    output reg  [MONEY_WIDTH-1:0]   total_revenue
);

    always @(posedge clk) begin
        if (rst) begin
            total_transactions     <= {COUNTER_WIDTH{1'b0}};
            successful_vends       <= {COUNTER_WIDTH{1'b0}};
            cancelled_transactions <= {COUNTER_WIDTH{1'b0}};
            invalid_coin_count     <= {COUNTER_WIDTH{1'b0}};
            online_payment_count   <= {COUNTER_WIDTH{1'b0}};
            cash_transaction_count <= {COUNTER_WIDTH{1'b0}};
            total_revenue          <= {MONEY_WIDTH{1'b0}};
        end else begin
            // 1. Successful Vend Event
            if (dispense_start) begin
                successful_vends   <= successful_vends + 1'b1;
                total_transactions <= total_transactions + 1'b1;
                total_revenue      <= total_revenue + vend_price;

                if (online_paid_flag || online_pay_approved) begin
                    online_payment_count <= online_payment_count + 1'b1;
                end else begin
                    cash_transaction_count <= cash_transaction_count + 1'b1;
                end
            end

            // 2. Cancellation Event
            if (calc_refund_en) begin
                cancelled_transactions <= cancelled_transactions + 1'b1;
                total_transactions     <= total_transactions + 1'b1;
            end

            // 3. Invalid Coin Event
            if (coin_reject_strobe) begin
                invalid_coin_count <= invalid_coin_count + 1'b1;
            end
        end
    end

endmodule
