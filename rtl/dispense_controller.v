// ============================================================================
// Module: dispense_controller
// Description: Synchronous product dispensing duration timer and strobe unit
//              for the Digital Vending Machine controller.
// Standard: IEEE 1364-2001 (Verilog-2001)
// ============================================================================

`timescale 1ns / 1ps

module dispense_controller #(
    parameter SEL_WIDTH            = 2,
    parameter DISPENSE_CYCLES      = 4,
    parameter DISPENSE_TIMER_WIDTH = 3
)(
    input  wire                 clk,
    input  wire                 rst,

    input  wire                 dispense_start,
    input  wire [SEL_WIDTH-1:0] selected_prod_id,

    output reg                  dispense_valid,
    output reg  [SEL_WIDTH-1:0] dispense_prod_id,
    output reg                  dispense_done
);

    reg [DISPENSE_TIMER_WIDTH-1:0] r_timer;

    always @(posedge clk) begin
        if (rst) begin
            dispense_valid   <= 1'b0;
            dispense_prod_id <= {SEL_WIDTH{1'b0}};
            dispense_done    <= 1'b0;
            r_timer          <= {DISPENSE_TIMER_WIDTH{1'b0}};
        end else if (dispense_start) begin
            dispense_prod_id <= selected_prod_id;
            dispense_valid   <= 1'b1;
            dispense_done    <= 1'b0;
            r_timer          <= {DISPENSE_TIMER_WIDTH{1'b0}};
        end else if (dispense_valid) begin
            if (r_timer >= (DISPENSE_CYCLES - 1)) begin
                dispense_valid <= 1'b0;
                dispense_done  <= 1'b1;
                r_timer        <= {DISPENSE_TIMER_WIDTH{1'b0}};
            end else begin
                r_timer        <= r_timer + 1'b1;
                dispense_done  <= 1'b0;
            end
        end else begin
            dispense_done <= 1'b0;
        end
    end

endmodule
