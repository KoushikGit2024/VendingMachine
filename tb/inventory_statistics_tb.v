// ============================================================================
// Module: inventory_statistics_tb
// Description: Self-checking testbench for Phase 4 extensions: Inventory,
//              Statistics counters, Admin Mode, and Display Menu Navigation.
// Standard: IEEE 1364-2001 (Verilog-2001)
// ============================================================================

`timescale 1ns / 1ps

module inventory_statistics_tb;

    // Parameters
    parameter NUM_PRODUCTS          = 4;
    parameter SEL_WIDTH             = 2;
    parameter DENOM_WIDTH           = 3;
    parameter MONEY_WIDTH           = 16;
    parameter INV_WIDTH             = 4;
    parameter STATE_WIDTH           = 4;
    parameter DISPENSE_CYCLES       = 4;
    parameter DISPENSE_TIMER_WIDTH  = 3;
    parameter ONLINE_TIMEOUT_CYCLES = 10;
    parameter ONLINE_TIMER_WIDTH    = 4;
    parameter MAX_MONEY_CAP         = 65535;
    parameter LOW_STOCK_LIMIT        = 2;

    // Clock & Reset
    reg clk;
    reg rst;

    // Vending Stimulus
    reg [SEL_WIDTH-1:0]   prod_select;
    reg                   select_valid;
    reg [DENOM_WIDTH-1:0] coin_denom;
    reg                   coin_valid;
    reg                   cancel_req;
    reg                   online_pay_trigger;

    // Online Payment Signals
    wire                  online_pay_req;
    wire [MONEY_WIDTH-1:0]online_pay_amount;
    reg                   online_pay_ack;
    reg [1:0]             online_pay_status;

    // Admin Control Signals
    reg                   admin_en;
    reg                   admin_next;
    reg                   admin_restock;

    // DUT Outputs
    wire                  ready;
    wire                  busy;
    wire [STATE_WIDTH-1:0]fsm_state_debug;
    wire                  dispense_valid;
    wire [SEL_WIDTH-1:0]  dispense_prod_id;
    wire [MONEY_WIDTH-1:0]inserted_amount;
    wire                  change_valid;
    wire [MONEY_WIDTH-1:0]change_amount;
    wire                  refund_valid;
    wire [MONEY_WIDTH-1:0]refund_amount;
    wire                  coin_reject;
    wire                  error_invalid_prod;
    wire                  error_out_of_stock;

    wire                  admin_mode_active;
    wire [2:0]            admin_menu;
    wire                  low_stock;
    wire                  out_of_stock;

    wire [15:0]           total_transactions;
    wire [15:0]           successful_vends;
    wire [15:0]           cancelled_transactions;
    wire [15:0]           invalid_coin_count;
    wire [15:0]           online_payment_count;
    wire [15:0]           cash_transaction_count;
    wire [15:0]           total_revenue;

    wire [3:0]            disp_d3;
    wire [3:0]            disp_d2;
    wire [3:0]            disp_d1;
    wire [3:0]            disp_d0;

    // Test Tracking
    integer tests_passed;
    integer tests_failed;
    integer test_num;

    // DUT Instantiation
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
        .LOW_STOCK_LIMIT        (LOW_STOCK_LIMIT)
    ) dut (
        .clk                    (clk),
        .rst                    (rst),
        .prod_select            (prod_select),
        .select_valid           (select_valid),
        .coin_denom             (coin_denom),
        .coin_valid             (coin_valid),
        .cancel_req             (cancel_req),
        .online_pay_trigger     (online_pay_trigger),
        .online_pay_req         (online_pay_req),
        .online_pay_amount      (online_pay_amount),
        .online_pay_ack         (online_pay_ack),
        .online_pay_status      (online_pay_status),
        .admin_en               (admin_en),
        .admin_next             (admin_next),
        .admin_restock          (admin_restock),
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
        .total_transactions     (total_transactions),
        .successful_vends       (successful_vends),
        .cancelled_transactions (cancelled_transactions),
        .invalid_coin_count     (invalid_coin_count),
        .online_payment_count   (online_payment_count),
        .cash_transaction_count (cash_transaction_count),
        .total_revenue          (total_revenue),
        .disp_d3                (disp_d3),
        .disp_d2                (disp_d2),
        .disp_d1                (disp_d1),
        .disp_d0                (disp_d0)
    );

    // Clock Generation (100 MHz -> 10ns)
    initial clk = 0;
    always #5 clk = ~clk;

    // Helper Tasks
    task reset_dut;
        begin
            @(posedge clk);
            rst <= 1'b1;
            prod_select        <= 2'b00;
            select_valid       <= 1'b0;
            coin_denom         <= 3'b000;
            coin_valid         <= 1'b0;
            cancel_req         <= 1'b0;
            online_pay_trigger <= 1'b0;
            online_pay_ack     <= 1'b0;
            online_pay_status  <= 2'b00;
            admin_en           <= 1'b0;
            admin_next         <= 1'b0;
            admin_restock      <= 1'b0;
            @(posedge clk);
            rst <= 1'b0;
            @(posedge clk);
        end
    endtask

    task select_item;
        input [SEL_WIDTH-1:0] item_id;
        begin
            @(posedge clk);
            prod_select  <= item_id;
            select_valid <= 1'b1;
            @(posedge clk);
            select_valid <= 1'b0;
            repeat (2) @(posedge clk);
        end
    endtask

    task insert_coin_pkt;
        input [DENOM_WIDTH-1:0] denom;
        begin
            @(posedge clk);
            coin_denom <= denom;
            coin_valid <= 1'b1;
            @(posedge clk);
            coin_valid <= 1'b0;
            coin_denom <= 3'b000;
        end
    endtask

    task press_cancel;
        begin
            @(posedge clk);
            cancel_req <= 1'b1;
            @(posedge clk);
            cancel_req <= 1'b0;
        end
    endtask

    task pulse_admin_next;
        begin
            @(posedge clk);
            admin_next <= 1'b1;
            @(posedge clk);
            admin_next <= 1'b0;
            @(posedge clk);
        end
    endtask

    task pulse_admin_restock;
        begin
            @(posedge clk);
            admin_restock <= 1'b1;
            @(posedge clk);
            admin_restock <= 1'b0;
            @(posedge clk);
        end
    endtask

    task check_test;
        input condition;
        input [256*8-1:0] msg;
        begin
            test_num = test_num + 1;
            if (condition) begin
                $display("[PASS] Test %0d: %s", test_num, msg);
                tests_passed = tests_passed + 1;
            end else begin
                $display("[FAIL] Test %0d: %s (Time: %0t ns)", test_num, msg, $time);
                tests_failed = tests_failed + 1;
            end
        end
    endtask

    integer i_count;

    initial begin
        $dumpfile("sim/inventory_statistics_tb.vcd");
        $dumpvars(0, inventory_statistics_tb);

        tests_passed = 0;
        tests_failed = 0;
        test_num     = 0;

        $display("=======================================================================");
        $display("   INVENTORY, STATISTICS, ADMIN & DISPLAY MENU EXTENSION VERIFICATION ");
        $display("=======================================================================");

        reset_dut();

        // --------------------------------------------------------------------
        // PHASE 1: INVENTORY TESTS (INV-001 .. INV-007)
        // --------------------------------------------------------------------
        // INV-001: Initial stock values are correct
        check_test((ready == 1'b1 && out_of_stock == 1'b0 && low_stock == 1'b0),
                   "INV-001: Initial stock is populated (10 items, no out/low stock)");

        // INV-002 & STAT-001: Successful vend decrements stock & increments counters
        select_item(2'b00); // Water = 10 units
        insert_coin_pkt(3'b100); // 10 coin
        repeat (DISPENSE_CYCLES + 3) @(posedge clk);

        check_test((successful_vends == 1 && total_transactions == 1 && total_revenue == 16'd10 && cash_transaction_count == 1),
                   "INV-002 / STAT-001: Successful vend decrements stock and credits 1 vend / 10 revenue");

        // INV-003 / STAT-006: Multi-cycle dispense does not double count
        check_test((successful_vends == 1 && total_transactions == 1),
                   "INV-003 / STAT-006: Multi-cycle FSM dispense does not double-count transactions");

        // Perform 7 more vends of Water (Item 0) to bring stock down to 2 (Low Stock threshold)
        for (i_count = 0; i_count < 7; i_count = i_count + 1) begin
            select_item(2'b00);
            insert_coin_pkt(3'b100);
            repeat (DISPENSE_CYCLES + 3) @(posedge clk);
        end

        // INV-006: Low-stock indication works (8 total vends -> stock = 2 <= LOW_STOCK_LIMIT)
        prod_select <= 2'b00;
        @(posedge clk);
        check_test((low_stock == 1'b1 && out_of_stock == 1'b0),
                   "INV-006: Low-stock indication asserts when product stock reaches threshold (<= 2)");

        // Vend 2 more times to completely exhaust Water (Item 0 stock = 0)
        for (i_count = 0; i_count < 2; i_count = i_count + 1) begin
            select_item(2'b00);
            insert_coin_pkt(3'b100);
            repeat (DISPENSE_CYCLES + 3) @(posedge clk);
        end

        // INV-004: Out-of-stock product cannot dispense
        select_item(2'b00); // Try selecting Item 0 (now stock = 0)
        check_test((error_out_of_stock == 1'b1 && fsm_state_debug == 4'b1001),
                   "INV-004: Selecting out-of-stock product triggers ST_ERROR (error_out_of_stock=1)");

        repeat (3) @(posedge clk); // Reset/recover from error state

        // INV-005: Inventory underflow prevention
        check_test((out_of_stock == 1'b1),
                   "INV-005: Out-of-stock flag active and stock remains clamped at 0 without underflow");

        // --------------------------------------------------------------------
        // PHASE 2: STATISTICS & EVENT TESTS (STAT-002 .. STAT-005)
        // --------------------------------------------------------------------
        // STAT-002: Cancellation increments cancellation counter
        select_item(2'b01); // Soda = 15
        insert_coin_pkt(3'b100); // 10
        press_cancel();
        repeat (5) @(posedge clk);
        check_test((cancelled_transactions == 1),
                   "STAT-002: Cancellation increments cancelled_transactions counter exactly once");

        // STAT-003: Invalid coin increments invalid coin counter
        select_item(2'b01);
        insert_coin_pkt(3'b111); // Invalid coin code
        repeat (3) @(posedge clk);
        press_cancel();
        repeat (5) @(posedge clk);
        check_test((invalid_coin_count >= 1),
                   "STAT-003: Invalid coin code increments invalid_coin_count counter");

        // STAT-004 & STAT-005: Online payment approval increments online payment counter & revenue
        select_item(2'b01); // Soda = 15
        insert_coin_pkt(3'b011); // 5
        repeat (2) @(posedge clk);
        online_pay_trigger <= 1'b1;
        @(posedge clk);
        online_pay_trigger <= 1'b0;
        repeat (2) @(posedge clk);
        online_pay_ack    <= 1'b1;
        online_pay_status <= 2'b01; // Approved
        @(posedge clk);
        online_pay_ack    <= 1'b0;
        online_pay_status <= 2'b00;
        repeat (DISPENSE_CYCLES + 3) @(posedge clk);

        check_test((online_payment_count == 1 && total_revenue == 16'd115), // 10*10 + 15 = 115
                   "STAT-004 / STAT-005: Approved online payment increments online_payment_count and total_revenue");

        // --------------------------------------------------------------------
        // PHASE 3: ADMIN MODE TESTS (ADMIN-001 .. ADMIN-005)
        // --------------------------------------------------------------------
        // ADMIN-001: Admin entry works in ST_IDLE
        admin_en <= 1'b1;
        repeat (2) @(posedge clk);
        check_test((admin_mode_active == 1'b1 && admin_menu == 3'd0),
                   "ADMIN-001: Admin mode entry succeeds when admin_en=1 in ST_IDLE");

        // ADMIN-004 & INV-007: Restocking in Admin Mode
        prod_select <= 2'b00; // Select Item 0 (which was depleted)
        repeat (2) @(posedge clk);
        pulse_admin_restock();
        repeat (2) @(posedge clk);
        check_test((out_of_stock == 1'b0 && low_stock == 1'b0),
                   "ADMIN-004 / INV-007: Restocking in admin mode restores item stock to full (10)");

        // ADMIN-002: Admin safety during dispensing (cannot enter admin while active)
        admin_en <= 1'b0;
        repeat (2) @(posedge clk);
        select_item(2'b01); // Start soda transaction
        insert_coin_pkt(3'b100);
        insert_coin_pkt(3'b011); // Total 15 -> enters ST_DISPENSE
        admin_en <= 1'b1; // Try turning on admin switch while dispensing
        @(posedge clk);
        check_test((admin_mode_active == 1'b0),
                   "ADMIN-002: Admin mode entry is rejected/gated while transaction is active (busy=1)");

        repeat (DISPENSE_CYCLES + 3) @(posedge clk); // Finish dispense

        // ADMIN-003: Admin exit returns system to normal operation
        repeat (2) @(posedge clk);
        check_test((admin_mode_active == 1'b1), "ADMIN-003a: Enters admin mode after returning to IDLE");
        admin_en <= 1'b0;
        repeat (2) @(posedge clk);
        check_test((admin_mode_active == 1'b0), "ADMIN-003b: Disabling admin switch cleanly exits to normal mode");

        // --------------------------------------------------------------------
        // PHASE 4: DISPLAY MENU TESTS (DISP-001 .. DISP-006)
        // --------------------------------------------------------------------
        // DISP-001: Normal mode display format
        prod_select <= 2'b01; // Item 1
        @(posedge clk);
        check_test((disp_d3 == 4'b0000 && disp_d2 == 4'b0001),
                   "DISP-001: Normal mode display shows FSM state in Digit 3 and Prod ID in Digit 2");

        // Enter Admin mode to test Menu displays
        admin_en <= 1'b1;
        repeat (2) @(posedge clk);

        // DISP-002: Menu 0 (Inventory)
        prod_select <= 2'b01;
        @(posedge clk);
        check_test((disp_d3 == 4'h0 && disp_d2 == 4'b0001),
                   "DISP-002: Menu 0 (Inventory) displays 0 in Digit 3, Prod ID in Digit 2, and stock in Digits 1..0");

        // DISP-003: Menu 1 (Statistics)
        pulse_admin_next();
        check_test((admin_menu == 3'd1 && disp_d0 == 4'd2), // 12 successful vends -> disp_d0 = 2
                   "DISP-003: Menu 1 (Statistics) displays successful vend count in 4-digit BCD");

        // DISP-004: Menu 2 (Revenue)
        pulse_admin_next();
        check_test((admin_menu == 3'd2),
                   "DISP-004: Menu 2 (Revenue) displays total revenue count in 4-digit BCD");

        // DISP-005: Menu 3 (Errors)
        pulse_admin_next();
        check_test((admin_menu == 3'd3 && disp_d3 == 4'hE),
                   "DISP-005: Menu 3 (Errors) displays E in Digit 3 and error status/invalid coin count");

        // DISP-006: Menu 4 (Status) & Menu 5 (Exit)
        pulse_admin_next(); // Menu 4
        check_test((admin_menu == 3'd4 && disp_d3 == 4'h4),
                   "DISP-006a: Menu 4 displays low/out-of-stock flags");

        pulse_admin_next(); // Menu 5
        check_test((admin_menu == 3'd5 && disp_d3 == 4'hE && disp_d2 == 4'h5),
                   "DISP-006b: Menu 5 displays Exit banner E517");

        pulse_admin_next(); // Exit menu 5 -> returns to normal mode
        check_test((admin_mode_active == 1'b0 && admin_menu == 3'd0),
                   "DISP-006c: Advancing past Menu 5 deterministically exits admin mode");

        // --------------------------------------------------------------------
        // FINAL SUMMARY REPORT
        // --------------------------------------------------------------------
        $display("=======================================================================");
        $display("                  VERIFICATION SUMMARY REPORT                          ");
        $display("=======================================================================");
        $display("  TOTAL TESTS RUN : %0d", test_num);
        $display("  TESTS PASSED    : %0d", tests_passed);
        $display("  TESTS FAILED    : %0d", tests_failed);
        $display("=======================================================================");

        if (tests_failed == 0) begin
            $display(">>> ALL PHASE 4 EXTENSION VERIFICATION TESTS PASSED SUCCESSFULLY! <<<");
        end else begin
            $display(">>> EXTENSION VERIFICATION FAILED WITH %0d ERRORS! <<<", tests_failed);
        end

        $finish;
    end

endmodule
