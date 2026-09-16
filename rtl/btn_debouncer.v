// ============================================================================
// Module: btn_debouncer
// Description: 2-stage D-FF synchronizer and parameterized counter-based
//              debouncer with single-cycle press edge pulse generation.
// Standard: IEEE 1364-2001 (Verilog-2001)
// ============================================================================

`timescale 1ns / 1ps

module btn_debouncer #(
    parameter DEBOUNCE_CYCLES = 200000 // Default 2ms @ 100MHz
)(
    input  wire clk,
    input  wire rst,
    input  wire async_btn,
    output reg  btn_state,  // Debounced stable level
    output reg  btn_pulse   // Single-clock pulse on rising press edge
);

    // 2-stage synchronizer flip-flops
    reg sync_0;
    reg sync_1;

    // Counter register for debouncing window
    reg [31:0] r_count;
    reg        r_state_d;

    // 1. Double-flop synchronizer
    always @(posedge clk) begin
        if (rst) begin
            sync_0 <= 1'b0;
            sync_1 <= 1'b0;
        end else begin
            sync_0 <= async_btn;
            sync_1 <= sync_0;
        end
    end

    // 2. Counter-based debouncer logic
    always @(posedge clk) begin
        if (rst) begin
            r_count   <= 32'd0;
            btn_state <= 1'b0;
            r_state_d <= 1'b0;
            btn_pulse <= 1'b0;
        end else begin
            r_state_d <= btn_state;

            if (sync_1 != btn_state) begin
                r_count <= r_count + 1'b1;
                if (r_count >= DEBOUNCE_CYCLES) begin
                    btn_state <= sync_1;
                    r_count   <= 32'd0;
                end
            end else begin
                r_count <= 32'd0;
            end

            // Rising edge pulse generation
            if (btn_state && !r_state_d) begin
                btn_pulse <= 1'b1;
            end else begin
                btn_pulse <= 1'b0;
            end
        end
    end

endmodule
