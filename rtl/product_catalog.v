// ============================================================================
// Module: product_catalog
// Description: Centralized product pricing lookup and inventory storage for
//              the Digital Vending Machine controller.
// Standard: IEEE 1364-2001 (Verilog-2001)
// ============================================================================

`timescale 1ns / 1ps

module product_catalog #(
    parameter NUM_PRODUCTS = 4,
    parameter SEL_WIDTH    = 2,
    parameter MONEY_WIDTH  = 16,
    parameter INV_WIDTH    = 4
)(
    input  wire                   clk,
    input  wire                   rst,

    input  wire [SEL_WIDTH-1:0]   prod_select,

    input  wire                   inventory_dec_en,
    input  wire [SEL_WIDTH-1:0]   dec_prod_id,

    output reg  [MONEY_WIDTH-1:0] prod_price,
    output reg                    prod_valid,
    output reg                    prod_in_stock,

    output wire [INV_WIDTH-1:0]   current_stock
);

    // Initial stock level per product slot (default: 10 items)
    localparam [INV_WIDTH-1:0] INITIAL_STOCK = 4'd10;

    // Inventory storage registers
    reg [INV_WIDTH-1:0] r_stock [0:NUM_PRODUCTS-1];

    integer i;

    // Combinational price, validity, and stock lookup
    always @(*) begin
        if (prod_select < NUM_PRODUCTS) begin
            prod_valid    = 1'b1;
            prod_in_stock = (r_stock[prod_select] > {INV_WIDTH{1'b0}});
            case (prod_select)
                2'b00:   prod_price = 16'd10; // Item 0: Water = 10
                2'b01:   prod_price = 16'd15; // Item 1: Soda  = 15
                2'b10:   prod_price = 16'd20; // Item 2: Chips = 20
                2'b11:   prod_price = 16'd25; // Item 3: Candy = 25
                default: prod_price = 16'd10;
            endcase
        end else begin
            prod_valid    = 1'b0;
            prod_in_stock = 1'b0;
            prod_price    = {MONEY_WIDTH{1'b0}};
        end
    end

    // Current stock output bus
    assign current_stock = (prod_select < NUM_PRODUCTS) ? r_stock[prod_select] : {INV_WIDTH{1'b0}};

    // Synchronous inventory decrement logic
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < NUM_PRODUCTS; i = i + 1) begin
                r_stock[i] <= INITIAL_STOCK;
            end
        end else if (inventory_dec_en) begin
            if ((dec_prod_id < NUM_PRODUCTS) && (r_stock[dec_prod_id] > {INV_WIDTH{1'b0}})) begin
                r_stock[dec_prod_id] <= r_stock[dec_prod_id] - 1'b1;
            end
        end
    end

endmodule
