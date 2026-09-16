// ============================================================================
// Module: vending_fsm
// Description: Central Finite State Machine for the Digital Vending Machine
//              controller. Manages machine operations, payment sequencing,
//              dispensing, change/refund routing, and error recovery.
// Standard: IEEE 1364-2001 (Verilog-2001)
// ============================================================================

`timescale 1ns / 1ps

module vending_fsm #(
    parameter SEL_WIDTH   = 2,
    parameter DENOM_WIDTH = 3,
    parameter MONEY_WIDTH = 16,
    parameter STATE_WIDTH = 4
)(
    input  wire                   clk,
    input  wire                   rst,

    input  wire [SEL_WIDTH-1:0]   prod_select,
    input  wire                   select_valid,
    input  wire                   coin_valid,
    input  wire [DENOM_WIDTH-1:0] coin_denom,
    input  wire                   cancel_req,
    input  wire                   online_pay_trigger,

    input  wire                   prod_valid,
    input  wire                   prod_in_stock,

    input  wire                   payment_sufficient,
    input  wire                   payment_exact,
    input  wire                   payment_over,
    input  wire                   payment_under,

    input  wire                   coin_accepted,
    input  wire                   coin_reject,

    input  wire                   online_pay_approved,
    input  wire                   online_pay_declined,
    input  wire                   online_pay_timeout,

    input  wire                   dispense_done,
    input  wire                   change_done,
    input  wire                   refund_done,

    input  wire                   accum_is_zero,
    input  wire                   accum_overflow,

    output reg  [SEL_WIDTH-1:0]   selected_prod_id,

    output reg  [DENOM_WIDTH-1:0] pending_coin_denom,
    output reg                    pending_coin_valid,

    output reg                    accum_enable,
    output reg                    accum_clear,

    output reg                    calc_change_en,
    output reg                    calc_refund_en,

    output reg                    dispense_start,
    output reg                    inventory_dec_en,

    output reg                    online_req_active,

    output reg                    cash_overpay_flag,
    output reg                    online_paid_flag,

    output reg                    ready,
    output reg                    busy,
    output reg  [STATE_WIDTH-1:0] current_state,

    output reg                    coin_reject_strobe,
    output reg                    error_invalid_prod,
    output reg                    error_out_of_stock
);

    // Operational State Definitions (4-bit binary encoding)
    localparam ST_IDLE        = 4'b0000;
    localparam ST_SELECT      = 4'b0001;
    localparam ST_PAYMENT     = 4'b0010;
    localparam ST_EVALUATE    = 4'b0011;
    localparam ST_ONLINE_WAIT = 4'b0100;
    localparam ST_DISPENSE    = 4'b0101;
    localparam ST_CHANGE      = 4'b0110;
    localparam ST_REFUND      = 4'b0111;
    localparam ST_COMPLETE    = 4'b1000;
    localparam ST_ERROR       = 4'b1001;

    reg [STATE_WIDTH-1:0] r_next_state;

    // Process 1: Sequential State & Metadata Register Update
    always @(posedge clk) begin
        if (rst) begin
            current_state      <= ST_IDLE;
            selected_prod_id   <= {SEL_WIDTH{1'b0}};
            pending_coin_denom <= {DENOM_WIDTH{1'b0}};
            pending_coin_valid <= 1'b0;
            cash_overpay_flag  <= 1'b0;
            online_paid_flag   <= 1'b0;
        end else begin
            current_state <= r_next_state;

            // Metadata updates on state transitions / events
            if (current_state == ST_IDLE && select_valid) begin
                selected_prod_id <= prod_select;
                if (coin_valid) begin
                    pending_coin_denom <= coin_denom;
                    pending_coin_valid <= 1'b1;
                end
            end else if (current_state == ST_SELECT) begin
                if (cancel_req || !prod_valid || !prod_in_stock) begin
                    pending_coin_valid <= 1'b0;
                end
            end else if (current_state == ST_PAYMENT) begin
                if (cancel_req) begin
                    pending_coin_valid <= 1'b0;
                end else if (pending_coin_valid && coin_accepted) begin
                    pending_coin_valid <= 1'b0;
                end
            end else if (current_state == ST_EVALUATE) begin
                if (payment_exact) begin
                    cash_overpay_flag <= 1'b0;
                    online_paid_flag  <= 1'b0;
                end else if (payment_over) begin
                    cash_overpay_flag <= 1'b1;
                    online_paid_flag  <= 1'b0;
                end
            end else if (current_state == ST_ONLINE_WAIT) begin
                if (online_pay_approved) begin
                    cash_overpay_flag <= 1'b0;
                    online_paid_flag  <= 1'b1;
                end
            end else if (current_state == ST_COMPLETE) begin
                cash_overpay_flag  <= 1'b0;
                online_paid_flag   <= 1'b0;
                pending_coin_valid <= 1'b0;
            end
        end
    end

    // Process 2: Combinational Next-State Logic
    always @(*) begin
        r_next_state = current_state;

        case (current_state)
            ST_IDLE: begin
                if (select_valid) begin
                    r_next_state = ST_SELECT;
                end else begin
                    r_next_state = ST_IDLE;
                end
            end

            ST_SELECT: begin
                if (cancel_req) begin
                    if (accum_is_zero)
                        r_next_state = ST_COMPLETE;
                    else
                        r_next_state = ST_REFUND;
                end else if (!prod_valid || !prod_in_stock) begin
                    r_next_state = ST_ERROR;
                end else begin
                    r_next_state = ST_PAYMENT;
                end
            end

            ST_PAYMENT: begin
                if (cancel_req) begin
                    if (accum_is_zero)
                        r_next_state = ST_COMPLETE;
                    else
                        r_next_state = ST_REFUND;
                end else if (online_pay_trigger) begin
                    if (payment_sufficient)
                        r_next_state = ST_EVALUATE;
                    else
                        r_next_state = ST_ONLINE_WAIT;
                end else if (pending_coin_valid) begin
                    if (coin_accepted)
                        r_next_state = ST_EVALUATE;
                    else
                        r_next_state = ST_PAYMENT;
                end else if (coin_valid) begin
                    if (coin_accepted)
                        r_next_state = ST_EVALUATE;
                    else
                        r_next_state = ST_PAYMENT;
                end else begin
                    r_next_state = ST_PAYMENT;
                end
            end

            ST_EVALUATE: begin
                if (cancel_req) begin
                    if (accum_is_zero)
                        r_next_state = ST_COMPLETE;
                    else
                        r_next_state = ST_REFUND;
                end else if (payment_exact || payment_over) begin
                    r_next_state = ST_DISPENSE;
                end else begin
                    r_next_state = ST_PAYMENT;
                end
            end

            ST_ONLINE_WAIT: begin
                if (cancel_req) begin
                    if (accum_is_zero)
                        r_next_state = ST_COMPLETE;
                    else
                        r_next_state = ST_REFUND;
                end else if (online_pay_approved) begin
                    r_next_state = ST_DISPENSE;
                end else if (online_pay_declined || online_pay_timeout) begin
                    r_next_state = ST_PAYMENT;
                end else begin
                    r_next_state = ST_ONLINE_WAIT;
                end
            end

            ST_DISPENSE: begin
                // Dispense protection: ignore cancel_req while dispensing
                if (dispense_done) begin
                    if (cash_overpay_flag)
                        r_next_state = ST_CHANGE;
                    else
                        r_next_state = ST_COMPLETE;
                end else begin
                    r_next_state = ST_DISPENSE;
                end
            end

            ST_CHANGE: begin
                if (change_done) begin
                    r_next_state = ST_COMPLETE;
                end else begin
                    r_next_state = ST_CHANGE;
                end
            end

            ST_REFUND: begin
                if (refund_done) begin
                    r_next_state = ST_COMPLETE;
                end else begin
                    r_next_state = ST_REFUND;
                end
            end

            ST_COMPLETE: begin
                r_next_state = ST_IDLE;
            end

            ST_ERROR: begin
                if (accum_is_zero)
                    r_next_state = ST_IDLE;
                else
                    r_next_state = ST_REFUND;
            end

            default: begin
                r_next_state = ST_IDLE;
            end
        endcase
    end

    // Process 3: Control Command Strobes & Output Decoding
    always @(*) begin
        // Default outputs
        ready              = 1'b0;
        busy               = 1'b1;
        accum_enable       = 1'b0;
        accum_clear        = 1'b0;
        calc_change_en     = 1'b0;
        calc_refund_en     = 1'b0;
        dispense_start     = 1'b0;
        inventory_dec_en   = 1'b0;
        online_req_active  = 1'b0;
        coin_reject_strobe = 1'b0;
        error_invalid_prod = 1'b0;
        error_out_of_stock = 1'b0;

        case (current_state)
            ST_IDLE: begin
                ready = 1'b1;
                busy  = 1'b0;
                if (!select_valid && coin_valid) begin
                    coin_reject_strobe = 1'b1; // Reject coin inserted without selection
                end
            end

            ST_SELECT: begin
                if (cancel_req && !accum_is_zero) begin
                    calc_refund_en = 1'b1;
                end
            end

            ST_PAYMENT: begin
                if (cancel_req) begin
                    if (!accum_is_zero)
                        calc_refund_en = 1'b1;
                end else if (!online_pay_trigger) begin
                    if (pending_coin_valid) begin
                        if (coin_accepted)
                            accum_enable = 1'b1;
                        else if (coin_reject)
                            coin_reject_strobe = 1'b1;
                    end else if (coin_valid) begin
                        if (coin_accepted)
                            accum_enable = 1'b1;
                        else
                            coin_reject_strobe = 1'b1;
                    end
                end
            end

            ST_EVALUATE: begin
                if (cancel_req) begin
                    if (!accum_is_zero)
                        calc_refund_en = 1'b1;
                end else if (payment_exact || payment_over) begin
                    dispense_start   = 1'b1;
                    inventory_dec_en = 1'b1;
                end
            end

            ST_ONLINE_WAIT: begin
                online_req_active = 1'b1;
                if (cancel_req) begin
                    if (!accum_is_zero)
                        calc_refund_en = 1'b1;
                end else if (online_pay_approved) begin
                    dispense_start   = 1'b1;
                    inventory_dec_en = 1'b1;
                end
            end

            ST_DISPENSE: begin
                if (coin_valid) begin
                    coin_reject_strobe = 1'b1; // Reject coins during dispensing
                end
                if (dispense_done && cash_overpay_flag) begin
                    calc_change_en = 1'b1;
                end
            end

            ST_CHANGE: begin
                // Change calculation active
            end

            ST_REFUND: begin
                // Refund calculation active
            end

            ST_COMPLETE: begin
                accum_clear = 1'b1;
            end

            ST_ERROR: begin
                if (!prod_valid)
                    error_invalid_prod = 1'b1;
                else if (!prod_in_stock)
                    error_out_of_stock = 1'b1;

                if (!accum_is_zero)
                    calc_refund_en = 1'b1;
            end

            default: begin
                accum_clear = 1'b1;
            end
        endcase
    end

endmodule
