// ============================================================================
// Module: vending_machine_top
// Description: Structural top-level coordinator for the Digital Vending
//              Machine controller. Interconnects datapath, FSM, inventory,
//              statistics, admin mode, and display menu controllers.
// Standard: IEEE 1364-2001 (Verilog-2001)
// ============================================================================

`timescale 1ns / 1ps

module vending_machine_top #(
    parameter NUM_PRODUCTS           = 4,
    parameter SEL_WIDTH              = 2,
    parameter DENOM_WIDTH            = 3,
    parameter MONEY_WIDTH            = 16,
    parameter INV_WIDTH              = 4,
    parameter STATE_WIDTH            = 4,
    parameter DISPENSE_CYCLES        = 4,
    parameter DISPENSE_TIMER_WIDTH   = 3,
    parameter ONLINE_TIMEOUT_CYCLES  = 1000,
    parameter ONLINE_TIMER_WIDTH     = 10,
    parameter MAX_MONEY_CAP          = 65535,
    parameter LOW_STOCK_LIMIT        = 2
)(
    input  wire                       clk,
    input  wire                       rst,

    input  wire [SEL_WIDTH-1:0]       prod_select,
    input  wire                       select_valid,

    input  wire [DENOM_WIDTH-1:0]     coin_denom,
    input  wire                       coin_valid,

    input  wire                       cancel_req,

    input  wire                       online_pay_trigger,
    output wire                       online_pay_req,
    output wire [MONEY_WIDTH-1:0]     online_pay_amount,
    input  wire                       online_pay_ack,
    input  wire [1:0]                 online_pay_status,

    // Admin & Peripheral Control Inputs
    input  wire                       admin_en,
    input  wire                       admin_next,
    input  wire                       admin_restock,

    output wire                       ready,
    output wire                       busy,
    output wire [STATE_WIDTH-1:0]     fsm_state_debug,

    output wire                       dispense_valid,
    output wire [SEL_WIDTH-1:0]       dispense_prod_id,

    output wire [MONEY_WIDTH-1:0]     inserted_amount,

    output wire                       change_valid,
    output wire [MONEY_WIDTH-1:0]     change_amount,

    output wire                       refund_valid,
    output wire [MONEY_WIDTH-1:0]     refund_amount,

    output wire                       coin_reject,
    output wire                       error_invalid_prod,
    output wire                       error_out_of_stock,

    // Admin & Extended Status Outputs
    output wire                       admin_mode_active,
    output wire [2:0]                 admin_menu,
    output wire                       low_stock,
    output wire                       out_of_stock,

    output wire [15:0]                total_transactions,
    output wire [15:0]                successful_vends,
    output wire [15:0]                cancelled_transactions,
    output wire [15:0]                invalid_coin_count,
    output wire [15:0]                online_payment_count,
    output wire [15:0]                cash_transaction_count,
    output wire [15:0]                total_revenue,

    output wire [3:0]                 disp_d3,
    output wire [3:0]                 disp_d2,
    output wire [3:0]                 disp_d1,
    output wire [3:0]                 disp_d0
);

    // Safe internal defaults for optional admin inputs (protect against floating Z)
    wire w_admin_en_safe      = (admin_en === 1'b1) ? 1'b1 : 1'b0;
    wire w_admin_next_safe    = (admin_next === 1'b1) ? 1'b1 : 1'b0;
    wire w_admin_restock_safe = (admin_restock === 1'b1) ? 1'b1 : 1'b0;

    // Internal Net Connections
    wire [SEL_WIDTH-1:0]   w_selected_prod_id;
    wire [DENOM_WIDTH-1:0] w_pending_coin_denom;
    wire                   w_pending_coin_valid;

    // Active coin decoder inputs
    wire [DENOM_WIDTH-1:0] w_active_coin_denom = w_pending_coin_valid ? w_pending_coin_denom : coin_denom;
    wire                   w_active_coin_valid = w_pending_coin_valid ? 1'b1 : coin_valid;

    wire [MONEY_WIDTH-1:0] w_coin_value;
    wire                   w_coin_accepted;
    wire                   w_coin_reject_proc;

    wire [SEL_WIDTH-1:0]   w_catalog_select = ready ? prod_select : w_selected_prod_id;
    wire [MONEY_WIDTH-1:0] w_prod_price;
    wire                   w_prod_valid;
    wire                   w_prod_in_stock;
    wire [INV_WIDTH-1:0]   w_current_stock;

    wire [INV_WIDTH-1:0]   w_stock_p0;
    wire [INV_WIDTH-1:0]   w_stock_p1;
    wire [INV_WIDTH-1:0]   w_stock_p2;
    wire [INV_WIDTH-1:0]   w_stock_p3;

    wire                   w_accum_enable;
    wire                   w_accum_clear;
    wire                   w_accum_is_zero;
    wire                   w_accum_overflow;

    wire                   w_payment_sufficient;
    wire                   w_payment_exact;
    wire                   w_payment_over;
    wire                   w_payment_under;

    wire                   w_calc_change_en;
    wire                   w_change_done;

    wire                   w_calc_refund_en;
    wire                   w_refund_done;

    wire                   w_online_req_active;
    wire                   w_online_pay_approved;
    wire                   w_online_pay_declined;
    wire                   w_online_pay_timeout;

    wire                   w_dispense_start;
    wire                   w_inventory_dec_en;
    wire                   w_dispense_done;

    wire                   w_cash_overpay_flag;
    wire                   w_online_paid_flag;
    wire                   w_coin_reject_strobe;

    wire                   w_restock_en;
    wire [SEL_WIDTH-1:0]   w_restock_prod_id;

    assign coin_reject = w_coin_reject_strobe | (coin_valid & w_coin_reject_proc);

    // 1. Coin Processor Module
    coin_processor #(
        .DENOM_WIDTH (DENOM_WIDTH),
        .MONEY_WIDTH (MONEY_WIDTH)
    ) u_coin_processor (
        .coin_denom    (w_active_coin_denom),
        .coin_valid    (w_active_coin_valid),
        .coin_value    (w_coin_value),
        .coin_accepted (w_coin_accepted),
        .coin_reject   (w_coin_reject_proc)
    );

    // 2. Inventory Controller Module
    inventory_controller #(
        .NUM_PRODUCTS    (NUM_PRODUCTS),
        .SEL_WIDTH       (SEL_WIDTH),
        .INV_WIDTH       (INV_WIDTH),
        .INITIAL_STOCK   (4'd10),
        .MAX_STOCK       (4'd10),
        .LOW_STOCK_LIMIT (LOW_STOCK_LIMIT)
    ) u_inventory_controller (
        .clk              (clk),
        .rst              (rst),
        .prod_select      (w_catalog_select),
        .inventory_dec_en (w_inventory_dec_en),
        .dec_prod_id      (w_selected_prod_id),
        .restock_en       (w_restock_en),
        .restock_prod_id  (w_restock_prod_id),
        .stock_p0         (w_stock_p0),
        .stock_p1         (w_stock_p1),
        .stock_p2         (w_stock_p2),
        .stock_p3         (w_stock_p3),
        .current_stock    (w_current_stock),
        .prod_in_stock    (w_prod_in_stock),
        .out_of_stock     (out_of_stock),
        .low_stock        (low_stock)
    );

    // 3. Product Catalog Module (Authoritative Pricing Table)
    product_catalog #(
        .NUM_PRODUCTS (NUM_PRODUCTS),
        .SEL_WIDTH    (SEL_WIDTH),
        .MONEY_WIDTH  (MONEY_WIDTH),
        .INV_WIDTH    (INV_WIDTH)
    ) u_product_catalog (
        .clk              (clk),
        .rst              (rst),
        .prod_select      (w_catalog_select),
        .inventory_dec_en (w_inventory_dec_en),
        .dec_prod_id      (w_selected_prod_id),
        .prod_price       (w_prod_price),
        .prod_valid       (w_prod_valid),
        .prod_in_stock    (), // Delegated to inventory_controller
        .current_stock    ()  // Delegated to inventory_controller
    );

    // 4. Payment Accumulator Module
    payment_accumulator #(
        .MONEY_WIDTH   (MONEY_WIDTH),
        .MAX_MONEY_CAP (MAX_MONEY_CAP)
    ) u_payment_accumulator (
        .clk            (clk),
        .rst            (rst),
        .coin_value     (w_coin_value),
        .coin_accepted  (w_coin_accepted),
        .accum_enable   (w_accum_enable),
        .accum_clear    (w_accum_clear),
        .accum_balance  (inserted_amount),
        .accum_is_zero  (w_accum_is_zero),
        .accum_overflow (w_accum_overflow)
    );

    // 5. Payment Evaluator Module
    payment_evaluator #(
        .MONEY_WIDTH (MONEY_WIDTH)
    ) u_payment_evaluator (
        .accum_balance      (inserted_amount),
        .prod_price         (w_prod_price),
        .payment_sufficient (w_payment_sufficient),
        .payment_exact      (w_payment_exact),
        .payment_over       (w_payment_over),
        .payment_under      (w_payment_under)
    );

    // 6. Change Calculator Module
    change_calculator #(
        .MONEY_WIDTH (MONEY_WIDTH)
    ) u_change_calculator (
        .clk            (clk),
        .rst            (rst),
        .calc_change_en (w_calc_change_en),
        .accum_balance  (inserted_amount),
        .prod_price     (w_prod_price),
        .change_amount  (change_amount),
        .change_valid   (change_valid),
        .change_done    (w_change_done)
    );

    // 7. Refund Controller Module
    refund_controller #(
        .MONEY_WIDTH (MONEY_WIDTH)
    ) u_refund_controller (
        .clk            (clk),
        .rst            (rst),
        .calc_refund_en (w_calc_refund_en),
        .accum_balance  (inserted_amount),
        .refund_amount  (refund_amount),
        .refund_valid   (refund_valid),
        .refund_done    (w_refund_done)
    );

    // 8. Online Payment Interface Module
    online_payment_interface #(
        .MONEY_WIDTH           (MONEY_WIDTH),
        .ONLINE_TIMEOUT_CYCLES (ONLINE_TIMEOUT_CYCLES),
        .ONLINE_TIMER_WIDTH    (ONLINE_TIMER_WIDTH)
    ) u_online_payment_interface (
        .clk                 (clk),
        .rst                 (rst),
        .online_req_active   (w_online_req_active),
        .prod_price          (w_prod_price),
        .accum_balance       (inserted_amount),
        .online_pay_req      (online_pay_req),
        .online_pay_amount   (online_pay_amount),
        .online_pay_ack      (online_pay_ack),
        .online_pay_status   (online_pay_status),
        .online_pay_approved (w_online_pay_approved),
        .online_pay_declined (w_online_pay_declined),
        .online_pay_timeout  (w_online_pay_timeout)
    );

    // 9. Dispense Controller Module
    dispense_controller #(
        .SEL_WIDTH            (SEL_WIDTH),
        .DISPENSE_CYCLES      (DISPENSE_CYCLES),
        .DISPENSE_TIMER_WIDTH (DISPENSE_TIMER_WIDTH)
    ) u_dispense_controller (
        .clk              (clk),
        .rst              (rst),
        .dispense_start   (w_dispense_start),
        .selected_prod_id (w_selected_prod_id),
        .dispense_valid   (dispense_valid),
        .dispense_prod_id (dispense_prod_id),
        .dispense_done    (w_dispense_done)
    );

    // 10. Central Operational FSM Module (Unmodified Verified Core)
    vending_fsm #(
        .SEL_WIDTH   (SEL_WIDTH),
        .DENOM_WIDTH (DENOM_WIDTH),
        .MONEY_WIDTH (MONEY_WIDTH),
        .STATE_WIDTH (STATE_WIDTH)
    ) u_vending_fsm (
        .clk                 (clk),
        .rst                 (rst),
        .prod_select         (prod_select),
        .select_valid        (select_valid),
        .coin_valid          (coin_valid),
        .coin_denom          (coin_denom),
        .cancel_req          (cancel_req),
        .online_pay_trigger  (online_pay_trigger),
        .prod_valid          (w_prod_valid),
        .prod_in_stock       (w_prod_in_stock),
        .payment_sufficient  (w_payment_sufficient),
        .payment_exact       (w_payment_exact),
        .payment_over        (w_payment_over),
        .payment_under       (w_payment_under),
        .coin_accepted       (w_coin_accepted),
        .coin_reject         (w_coin_reject_proc),
        .online_pay_approved (w_online_pay_approved),
        .online_pay_declined (w_online_pay_declined),
        .online_pay_timeout  (w_online_pay_timeout),
        .dispense_done       (w_dispense_done),
        .change_done         (w_change_done),
        .refund_done         (w_refund_done),
        .accum_is_zero       (w_accum_is_zero),
        .accum_overflow      (w_accum_overflow),
        .selected_prod_id    (w_selected_prod_id),
        .pending_coin_denom  (w_pending_coin_denom),
        .pending_coin_valid  (w_pending_coin_valid),
        .accum_enable        (w_accum_enable),
        .accum_clear         (w_accum_clear),
        .calc_change_en      (w_calc_change_en),
        .calc_refund_en      (w_calc_refund_en),
        .dispense_start      (w_dispense_start),
        .inventory_dec_en    (w_inventory_dec_en),
        .online_req_active   (w_online_req_active),
        .cash_overpay_flag   (w_cash_overpay_flag),
        .online_paid_flag    (w_online_paid_flag),
        .ready               (ready),
        .busy                (busy),
        .current_state       (fsm_state_debug),
        .coin_reject_strobe  (w_coin_reject_strobe),
        .error_invalid_prod  (error_invalid_prod),
        .error_out_of_stock  (error_out_of_stock)
    );

    // 11. Statistics Controller Module
    statistics_controller #(
        .MONEY_WIDTH   (MONEY_WIDTH),
        .COUNTER_WIDTH (16)
    ) u_statistics_controller (
        .clk                    (clk),
        .rst                    (rst),
        .dispense_start         (w_dispense_start),
        .calc_refund_en         (w_calc_refund_en),
        .coin_reject_strobe     (coin_reject),
        .online_paid_flag       (w_online_paid_flag),
        .online_pay_approved   (w_online_pay_approved),
        .vend_price             (w_prod_price),
        .total_transactions     (total_transactions),
        .successful_vends       (successful_vends),
        .cancelled_transactions (cancelled_transactions),
        .invalid_coin_count     (invalid_coin_count),
        .online_payment_count   (online_payment_count),
        .cash_transaction_count (cash_transaction_count),
        .total_revenue          (total_revenue)
    );

    // 12. Admin Controller Module
    admin_controller #(
        .SEL_WIDTH (SEL_WIDTH)
    ) u_admin_controller (
        .clk               (clk),
        .rst               (rst),
        .admin_en_sw       (w_admin_en_safe),
        .admin_next_sw     (w_admin_next_safe),
        .admin_restock_sw  (w_admin_restock_safe),
        .ready             (ready),
        .fsm_state         (fsm_state_debug),
        .prod_select       (prod_select),
        .admin_mode_active (admin_mode_active),
        .admin_menu        (admin_menu),
        .restock_en        (w_restock_en),
        .restock_prod_id   (w_restock_prod_id)
    );

    // 13. Display Menu Controller Module
    display_menu_controller #(
        .SEL_WIDTH   (SEL_WIDTH),
        .MONEY_WIDTH (MONEY_WIDTH),
        .INV_WIDTH   (INV_WIDTH)
    ) u_display_menu_controller (
        .admin_mode_active      (admin_mode_active),
        .admin_menu             (admin_menu),
        .fsm_state              (fsm_state_debug),
        .selected_prod_id       (dispense_valid ? dispense_prod_id : prod_select),
        .inserted_amount        (inserted_amount),
        .change_amount          (change_amount),
        .refund_amount          (refund_amount),
        .change_valid           (change_valid),
        .refund_valid           (refund_valid),
        .current_stock          (w_current_stock),
        .low_stock              (low_stock),
        .out_of_stock           (out_of_stock),
        .total_transactions     (total_transactions),
        .successful_vends       (successful_vends),
        .cancelled_transactions (cancelled_transactions),
        .invalid_coin_count     (invalid_coin_count),
        .total_revenue          (total_revenue),
        .error_invalid_prod     (error_invalid_prod),
        .error_out_of_stock     (error_out_of_stock),
        .disp_d3                (disp_d3),
        .disp_d2                (disp_d2),
        .disp_d1                (disp_d1),
        .disp_d0                (disp_d0)
    );

endmodule
