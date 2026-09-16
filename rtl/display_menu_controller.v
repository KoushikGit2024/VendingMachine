// ============================================================================
// Module: display_menu_controller
// Description: Decides display data for 4-digit 7-segment display based on
//              operating mode (Normal vs Admin Menu 0..5).
// Standard: IEEE 1364-2001 (Verilog-2001)
// ============================================================================

`timescale 1ns / 1ps

module display_menu_controller #(
    parameter SEL_WIDTH   = 2,
    parameter MONEY_WIDTH = 16,
    parameter INV_WIDTH   = 4
)(
    input  wire                 admin_mode_active,
    input  wire [2:0]           admin_menu,

    input  wire [3:0]           fsm_state,
    input  wire [SEL_WIDTH-1:0] selected_prod_id,
    input  wire [MONEY_WIDTH-1:0] inserted_amount,
    input  wire [MONEY_WIDTH-1:0] change_amount,
    input  wire [MONEY_WIDTH-1:0] refund_amount,
    input  wire                 change_valid,
    input  wire                 refund_valid,

    input  wire [INV_WIDTH-1:0] current_stock,
    input  wire                 low_stock,
    input  wire                 out_of_stock,

    input  wire [15:0]          total_transactions,
    input  wire [15:0]          successful_vends,
    input  wire [15:0]          cancelled_transactions,
    input  wire [15:0]          invalid_coin_count,
    input  wire [15:0]          total_revenue,

    input  wire                 error_invalid_prod,
    input  wire                 error_out_of_stock,

    output reg  [3:0]           disp_d3,
    output reg  [3:0]           disp_d2,
    output reg  [3:0]           disp_d1,
    output reg  [3:0]           disp_d0
);

    wire [15:0] active_money = change_valid ? change_amount : (refund_valid ? refund_amount : inserted_amount);

    always @(*) begin
        if (!admin_mode_active) begin
            // NORMAL MODE:
            // Digit 3: FSM State Code (0..F)
            // Digit 2: Selected Product ID (0..3)
            // Digit 1: Active Money Tens ((active_money / 10) % 10)
            // Digit 0: Active Money Ones (active_money % 10)
            disp_d3 = fsm_state;
            disp_d2 = {2'b00, selected_prod_id};
            disp_d1 = (active_money / 16'd10) % 16'd10;
            disp_d0 = active_money % 16'd10;
        end else begin
            // ADMIN MODE:
            case (admin_menu)
                3'd0: begin // MENU 0: Inventory viewing & Restock
                    disp_d3 = 4'h0;
                    disp_d2 = {2'b00, selected_prod_id};
                    disp_d1 = (current_stock / 4'd10) % 4'd10;
                    disp_d0 = current_stock % 4'd10;
                end

                3'd1: begin // MENU 1: Statistics (Successful Vends)
                    disp_d3 = (successful_vends / 16'd1000) % 16'd10;
                    disp_d2 = (successful_vends / 16'd100) % 16'd10;
                    disp_d1 = (successful_vends / 16'd10) % 16'd10;
                    disp_d0 = successful_vends % 16'd10;
                end

                3'd2: begin // MENU 2: Revenue
                    disp_d3 = (total_revenue / 16'd1000) % 16'd10;
                    disp_d2 = (total_revenue / 16'd100) % 16'd10;
                    disp_d1 = (total_revenue / 16'd10) % 16'd10;
                    disp_d0 = total_revenue % 16'd10;
                end

                3'd3: begin // MENU 3: Errors / Invalid coins
                    disp_d3 = 4'hE;
                    disp_d2 = {3'b0, (error_out_of_stock | error_invalid_prod)};
                    disp_d1 = (invalid_coin_count / 16'd10) % 16'd10;
                    disp_d0 = invalid_coin_count % 16'd10;
                end

                3'd4: begin // MENU 4: Stock Status (Low stock / Out of stock)
                    disp_d3 = 4'h4;
                    disp_d2 = {2'b00, selected_prod_id};
                    disp_d1 = {3'b0, low_stock};
                    disp_d0 = {3'b0, out_of_stock};
                end

                3'd5: begin // MENU 5: Exit
                    disp_d3 = 4'hE;
                    disp_d2 = 4'h5;
                    disp_d1 = 4'h1;
                    disp_d0 = 4'h7;
                end

                default: begin
                    disp_d3 = 4'h0;
                    disp_d2 = 4'h0;
                    disp_d1 = 4'h0;
                    disp_d0 = 4'h0;
                end
            endcase
        end
    end

endmodule
