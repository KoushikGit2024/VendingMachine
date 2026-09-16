// ============================================================================
// Module: seven_seg_display_ctrl
// Description: Time-multiplexed 4-digit 7-segment display driver for FPGA
//              board visual status (scans digit anodes and decodes cathodes).
// Standard: IEEE 1364-2001 (Verilog-2001)
// ============================================================================

`timescale 1ns / 1ps

module seven_seg_display_ctrl #(
    parameter CLK_FREQ_HZ = 100000000 // 100 MHz default
)(
    input  wire        clk,
    input  wire        rst,

    input  wire [3:0]  disp_d3, // Leftmost digit (Anode 3)
    input  wire [3:0]  disp_d2, // Digit 2 (Anode 2)
    input  wire [3:0]  disp_d1, // Digit 1 (Anode 1)
    input  wire [3:0]  disp_d0, // Rightmost digit (Anode 0)

    output reg  [3:0]  an,      // Active-low digit anodes [3:0]
    output reg  [6:0]  seg,     // Active-low cathode segments [A..G]
    output wire        dp       // Decimal point (active-low)
);

    assign dp = 1'b1; // Decimal point OFF by default

    // Refresh counter for 1kHz digit scanning (~250Hz per digit)
    reg [17:0] refresh_counter;
    wire [1:0] active_digit;

    always @(posedge clk) begin
        if (rst)
            refresh_counter <= 18'd0;
        else
            refresh_counter <= refresh_counter + 1'b1;
    end

    assign active_digit = refresh_counter[17:16];

    reg [3:0] hex_digit;

    // Multiplexer for 4 digits
    always @(*) begin
        case (active_digit)
            2'b00: begin // Digit 0 (Rightmost)
                an        = 4'b1110;
                hex_digit = disp_d0;
            end
            2'b01: begin // Digit 1
                an        = 4'b1101;
                hex_digit = disp_d1;
            end
            2'b10: begin // Digit 2
                an        = 4'b1011;
                hex_digit = disp_d2;
            end
            2'b11: begin // Digit 3 (Leftmost)
                an        = 4'b0111;
                hex_digit = disp_d3;
            end
        endcase
    end

    // 7-segment Hex Decoder (Active-Low outputs: 0 = LED ON, 1 = LED OFF)
    // Segments: {g, f, e, d, c, b, a}
    always @(*) begin
        case (hex_digit)
            4'h0: seg = 7'b1000000; // 0
            4'h1: seg = 7'b1111001; // 1
            4'h2: seg = 7'b0100100; // 2
            4'h3: seg = 7'b0110000; // 3
            4'h4: seg = 7'b0011001; // 4
            4'h5: seg = 7'b0100010; // 5
            4'h6: seg = 7'b0100000; // 6
            4'h7: seg = 7'b1111000; // 7
            4'h8: seg = 7'b0000000; // 8
            4'h9: seg = 7'b0110000; // 9
            4'hA: seg = 7'b0001000; // A
            4'hB: seg = 7'b0000011; // b
            4'hC: seg = 7'b1000110; // C
            4'hD: seg = 7'b0100001; // d
            4'hE: seg = 7'b0000110; // E
            4'hF: seg = 7'b0001110; // F
            default: seg = 7'b1111111;
        endcase
    end

endmodule
