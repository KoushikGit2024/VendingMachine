// ============================================================================
// Module: admin_controller
// Description: Admin / Maintenance Mode controller for Digital Vending Machine.
//              Manages admin mode entry, safety gating, menu navigation,
//              and restocking triggers.
// Standard: IEEE 1364-2001 (Verilog-2001)
// ============================================================================

`timescale 1ns / 1ps

module admin_controller #(
    parameter SEL_WIDTH = 2
)(
    input  wire                 clk,
    input  wire                 rst,

    input  wire                 admin_en_sw,     // SW15: Admin enable switch
    input  wire                 admin_next_sw,   // SW14 / button: Menu advance switch/pulse
    input  wire                 admin_restock_sw,// SW13 / button: Restock trigger switch/pulse

    input  wire                 ready,           // 1'b1 when vending FSM is in ST_IDLE
    input  wire [3:0]           fsm_state,       // Debug FSM state
    input  wire [SEL_WIDTH-1:0] prod_select,     // Current product selection switches

    output reg                  admin_mode_active,// 1'b1 when system is in Admin Mode
    output reg  [2:0]           admin_menu,       // 0:Stock, 1:Stats, 2:Revenue, 3:Errors, 4:Status, 5:Exit
    output reg                  restock_en,       // Restock pulse output
    output wire [SEL_WIDTH-1:0] restock_prod_id   // Product ID to restock
);

    assign restock_prod_id = prod_select;

    // Edge detector for admin_next_sw and admin_restock_sw
    reg r_next_d;
    reg r_restock_d;
    wire w_next_pulse    = admin_next_sw && !r_next_d;
    wire w_restock_pulse = admin_restock_sw && !r_restock_d;

    always @(posedge clk) begin
        if (rst) begin
            r_next_d    <= 1'b0;
            r_restock_d <= 1'b0;
        end else begin
            r_next_d    <= admin_next_sw;
            r_restock_d <= admin_restock_sw;
        end
    end

    // Admin State & Menu Navigation
    always @(posedge clk) begin
        if (rst) begin
            admin_mode_active <= 1'b0;
            admin_menu        <= 3'd0;
            restock_en        <= 1'b0;
        end else begin
            restock_en <= 1'b0; // Default pulse low

            if (!admin_mode_active) begin
                // Admin Entry Condition: admin_en_sw IS HIGH AND machine IS IN ST_IDLE (ready == 1)
                if (admin_en_sw && ready) begin
                    admin_mode_active <= 1'b1;
                    admin_menu        <= 3'd0;
                end
            end else begin
                // In Admin Mode:
                if (!admin_en_sw) begin
                    admin_mode_active <= 1'b0;
                    admin_menu        <= 3'd0;
                end else if (w_next_pulse) begin
                    if (admin_menu == 3'd5) begin
                        admin_mode_active <= 1'b0;
                        admin_menu        <= 3'd0;
                    end else begin
                        admin_menu <= admin_menu + 1'b1;
                    end
                end

                // Restock Action: allowed in Admin Mode when machine is in ST_IDLE
                if (admin_mode_active && ready && w_restock_pulse && (admin_menu == 3'd0 || admin_menu == 3'd4)) begin
                    restock_en <= 1'b1;
                end
            end
        end
    end

endmodule
