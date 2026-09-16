// ============================================================================
// Module: vending_machine_board_wrapper
// Description: Top-level physical FPGA evaluation board wrapper (Basys-3)
//              integrating button synchronizers, debouncers, 7-segment display
//              multiplexer, LED status mapping, admin mode controls, and the
//              core vending controller.
// Standard: IEEE 1364-2001 (Verilog-2001)
// ============================================================================

`timescale 1ns / 1ps

module vending_machine_board_wrapper #(
    parameter NUM_PRODUCTS          = 4,
    parameter SEL_WIDTH             = 2,
    parameter DENOM_WIDTH           = 3,
    parameter MONEY_WIDTH           = 16,
    parameter INV_WIDTH             = 4,
    parameter STATE_WIDTH           = 4,
    parameter DISPENSE_CYCLES       = 100000000, // 1 sec @ 100MHz for physical visibility
    parameter DISPENSE_TIMER_WIDTH  = 28,
    parameter ONLINE_TIMEOUT_CYCLES = 500000000, // 5 sec @ 100MHz for physical visibility
    parameter ONLINE_TIMER_WIDTH    = 30,
    parameter MAX_MONEY_CAP         = 65535,
    parameter DEBOUNCE_CYCLES       = 200000     // 2ms debounce @ 100MHz
)(
    input  wire        clk_100mhz,        // Physical 100MHz oscillator
    input  wire        btn_rst,           // Physical reset button
    input  wire        btn_select,        // Pushbutton to select product
    input  wire [1:0]  sw_prod_sel,       // 2 switches for product ID
    input  wire        btn_coin,          // Pushbutton to insert coin
    input  wire [2:0]  sw_coin_denom,     // 3 switches for coin denomination code
    input  wire        btn_cancel,        // Pushbutton to cancel transaction
    input  wire        btn_online_trigger,// Pushbutton to trigger online payment
    input  wire        btn_online_ack,    // Pushbutton to ACK online payment
    input  wire [1:0]  sw_online_status,  // 2 switches for online payment status code

    // Extended Admin Control Switches
    input  wire        sw_admin_en,       // SW15 (R2): Admin mode enable switch
    input  wire        sw_admin_next,     // SW14 (T1): Admin menu next switch
    input  wire        sw_admin_restock,  // SW13 (U1): Admin restock trigger switch

    output wire [3:0]  an,                // Active-low 7-segment digit anodes
    output wire [6:0]  seg,               // Active-low 7-segment cathodes
    output wire        dp,                // Active-low decimal point
    output wire [15:0] led                // 16 Status LEDs
);

    // Synchronized and Debounced Internal Signal Wires
    wire w_rst_pulse;
    wire w_rst_level;

    wire w_select_valid;
    wire w_coin_valid;
    wire w_cancel_req;
    wire w_online_pay_trigger;
    wire w_online_pay_ack;

    // Direct Synchronizers for level signals
    reg [1:0] sync_prod_sel [1:0];
    reg [2:0] sync_coin_denom [1:0];
    reg [1:0] sync_online_status [1:0];
    reg       sync_admin_en [1:0];
    reg       sync_admin_next [1:0];
    reg       sync_admin_restock [1:0];

    always @(posedge clk_100mhz) begin
        sync_prod_sel[0]      <= sw_prod_sel;
        sync_prod_sel[1]      <= sync_prod_sel[0];
        sync_coin_denom[0]    <= sw_coin_denom;
        sync_coin_denom[1]    <= sync_coin_denom[0];
        sync_online_status[0] <= sw_online_status;
        sync_online_status[1] <= sync_online_status[0];
        sync_admin_en[0]      <= sw_admin_en;
        sync_admin_en[1]      <= sync_admin_en[0];
        sync_admin_next[0]    <= sw_admin_next;
        sync_admin_next[1]    <= sync_admin_next[0];
        sync_admin_restock[0] <= sw_admin_restock;
        sync_admin_restock[1] <= sync_admin_restock[0];
    end

    // 1. Debouncer Instances
    btn_debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) u_deb_rst (
        .clk(clk_100mhz), .rst(1'b0), .async_btn(btn_rst), .btn_state(w_rst_level), .btn_pulse(w_rst_pulse)
    );

    btn_debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) u_deb_select (
        .clk(clk_100mhz), .rst(w_rst_level), .async_btn(btn_select), .btn_state(), .btn_pulse(w_select_valid)
    );

    btn_debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) u_deb_coin (
        .clk(clk_100mhz), .rst(w_rst_level), .async_btn(btn_coin), .btn_state(), .btn_pulse(w_coin_valid)
    );

    btn_debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) u_deb_cancel (
        .clk(clk_100mhz), .rst(w_rst_level), .async_btn(btn_cancel), .btn_state(), .btn_pulse(w_cancel_req)
    );

    btn_debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) u_deb_online_trig (
        .clk(clk_100mhz), .rst(w_rst_level), .async_btn(btn_online_trigger), .btn_state(), .btn_pulse(w_online_pay_trigger)
    );

    btn_debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) u_deb_online_ack (
        .clk(clk_100mhz), .rst(w_rst_level), .async_btn(btn_online_ack), .btn_state(), .btn_pulse(w_online_pay_ack)
    );

    // Core Interconnect Wires
    wire                    online_pay_req;
    wire [MONEY_WIDTH-1:0]  online_pay_amount;
    wire                    ready;
    wire                    busy;
    wire [STATE_WIDTH-1:0]  fsm_state_debug;
    wire                    dispense_valid;
    wire [SEL_WIDTH-1:0]    dispense_prod_id;
    wire [MONEY_WIDTH-1:0]  inserted_amount;
    wire                    change_valid;
    wire [MONEY_WIDTH-1:0]  change_amount;
    wire                    refund_valid;
    wire [MONEY_WIDTH-1:0]  refund_amount;
    wire                    coin_reject;
    wire                    error_invalid_prod;
    wire                    error_out_of_stock;

    wire                    admin_mode_active;
    wire [2:0]              admin_menu;
    wire                    low_stock;
    wire                    out_of_stock;

    wire [3:0]              disp_d3;
    wire [3:0]              disp_d2;
    wire [3:0]              disp_d1;
    wire [3:0]              disp_d0;

    // 2. Core Vending Machine Top Instance
    vending_machine_top #(
        .NUM_PRODUCTS          (NUM_PRODUCTS),
        .SEL_WIDTH             (SEL_WIDTH),
        .DENOM_WIDTH           (DENOM_WIDTH),
        .MONEY_WIDTH           (MONEY_WIDTH),
        .INV_WIDTH             (INV_WIDTH),
        .STATE_WIDTH           (STATE_WIDTH),
        .DISPENSE_CYCLES       (DISPENSE_CYCLES),
        .DISPENSE_TIMER_WIDTH  (DISPENSE_TIMER_WIDTH),
        .ONLINE_TIMEOUT_CYCLES (ONLINE_TIMEOUT_CYCLES),
        .ONLINE_TIMER_WIDTH    (ONLINE_TIMER_WIDTH),
        .MAX_MONEY_CAP         (MAX_MONEY_CAP),
        .LOW_STOCK_LIMIT        (2)
    ) u_core_top (
        .clk                    (clk_100mhz),
        .rst                    (w_rst_level),
        .prod_select            (sync_prod_sel[1]),
        .select_valid           (w_select_valid),
        .coin_denom             (sync_coin_denom[1]),
        .coin_valid             (w_coin_valid),
        .cancel_req             (w_cancel_req),
        .online_pay_trigger     (w_online_pay_trigger),
        .online_pay_req         (online_pay_req),
        .online_pay_amount      (online_pay_amount),
        .online_pay_ack         (w_online_pay_ack),
        .online_pay_status      (sync_online_status[1]),
        .admin_en               (sync_admin_en[1]),
        .admin_next             (sync_admin_next[1]),
        .admin_restock          (sync_admin_restock[1]),
        .ready                  (ready),
        .busy                   (busy),
        .fsm_state_debug        (fsm_state_debug),
        .dispense_valid         (dispense_valid),
        .dispense_prod_id       (dispense_prod_id),
        .inserted_amount        (inserted_amount),
        .change_valid           (change_valid),
        .change_amount          (change_amount),
        .refund_valid           (refund_valid),
        .refund_amount          (refund_amount),
        .coin_reject            (coin_reject),
        .error_invalid_prod     (error_invalid_prod),
        .error_out_of_stock     (error_out_of_stock),
        .admin_mode_active      (admin_mode_active),
        .admin_menu             (admin_menu),
        .low_stock              (low_stock),
        .out_of_stock           (out_of_stock),
        .total_transactions     (),
        .successful_vends       (),
        .cancelled_transactions (),
        .invalid_coin_count     (),
        .online_payment_count   (),
        .cash_transaction_count (),
        .total_revenue          (),
        .disp_d3                (disp_d3),
        .disp_d2                (disp_d2),
        .disp_d1                (disp_d1),
        .disp_d0                (disp_d0)
    );

    // 3. 7-Segment Display Controller Instance
    seven_seg_display_ctrl u_7seg (
        .clk     (clk_100mhz),
        .rst     (w_rst_level),
        .disp_d3 (disp_d3),
        .disp_d2 (disp_d2),
        .disp_d1 (disp_d1),
        .disp_d0 (disp_d0),
        .an      (an),
        .seg     (seg),
        .dp      (dp)
    );

    // 4. LED Status Driver Instance
    led_status_driver u_led_driver (
        .ready              (ready),
        .busy               (busy),
        .fsm_state          (fsm_state_debug),
        .dispense_valid     (dispense_valid),
        .dispense_prod_id   (dispense_prod_id),
        .change_valid       (change_valid),
        .refund_valid       (refund_valid),
        .online_pay_req     (online_pay_req),
        .coin_reject        (coin_reject),
        .error_invalid_prod (error_invalid_prod),
        .error_out_of_stock (error_out_of_stock),
        .low_stock          (low_stock),
        .admin_mode_active  (admin_mode_active),
        .led                (led)
    );

endmodule
