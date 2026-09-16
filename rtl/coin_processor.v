// ============================================================================
// Module: coin_processor
// Description: Pure combinational coin denomination decoder and validator for
//              the Digital Vending Machine controller.
// Standard: IEEE 1364-2001 (Verilog-2001)
// ============================================================================

`timescale 1ns / 1ps

module coin_processor #(
    parameter DENOM_WIDTH = 3,
    parameter MONEY_WIDTH = 16
)(
    input  wire [DENOM_WIDTH-1:0] coin_denom,
    input  wire                   coin_valid,

    output reg  [MONEY_WIDTH-1:0] coin_value,
    output reg                    coin_accepted,
    output reg                    coin_reject
);

    always @(*) begin
        // Default combinational outputs (prevents latch inference)
        coin_value    = {MONEY_WIDTH{1'b0}};
        coin_accepted = 1'b0;
        coin_reject   = 1'b0;

        if (coin_valid) begin
            case (coin_denom)
                3'b001: begin
                    coin_value    = {{MONEY_WIDTH-1{1'b0}}, 1'b1}; // Value: 1
                    coin_accepted = 1'b1;
                    coin_reject   = 1'b0;
                end
                3'b010: begin
                    coin_value    = {{MONEY_WIDTH-2{1'b0}}, 2'b10}; // Value: 2
                    coin_accepted = 1'b1;
                    coin_reject   = 1'b0;
                end
                3'b011: begin
                    coin_value    = {{MONEY_WIDTH-3{1'b0}}, 3'b101}; // Value: 5
                    coin_accepted = 1'b1;
                    coin_reject   = 1'b0;
                end
                3'b100: begin
                    coin_value    = {{MONEY_WIDTH-4{1'b0}}, 4'b1010}; // Value: 10
                    coin_accepted = 1'b1;
                    coin_reject   = 1'b0;
                end
                3'b101: begin
                    coin_value    = {{MONEY_WIDTH-5{1'b0}}, 5'b10100}; // Value: 20
                    coin_accepted = 1'b1;
                    coin_reject   = 1'b0;
                end
                default: begin
                    coin_value    = {MONEY_WIDTH{1'b0}};
                    coin_accepted = 1'b0;
                    coin_reject   = 1'b1; // Invalid / unrecognized coin
                end
            endcase
        end
    end

endmodule
