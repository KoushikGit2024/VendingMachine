// ============================================================================
// Module: inventory_controller
// Description: Dedicated inventory management controller for Digital Vending
//              Machine. Tracks stock per product slot, detects low/out stock,
//              prevents underflow, and supports synchronous restocking in admin mode.
// Standard: IEEE 1364-2001 (Verilog-2001)
// ============================================================================

`timescale 1ns / 1ps

module inventory_controller #(
    parameter NUM_PRODUCTS    = 4,
    parameter SEL_WIDTH       = 2,
    parameter INV_WIDTH       = 4,
    parameter INITIAL_STOCK   = 4'd10,
    parameter MAX_STOCK       = 4'd10,
    parameter LOW_STOCK_LIMIT = 4'd2
)(
    input  wire                   clk,
    input  wire                   rst,

    input  wire [SEL_WIDTH-1:0]   prod_select,
    input  wire                   inventory_dec_en,
    input  wire [SEL_WIDTH-1:0]   dec_prod_id,

    input  wire                   restock_en,
    input  wire [SEL_WIDTH-1:0]   restock_prod_id,

    output wire [INV_WIDTH-1:0]   stock_p0,
    output wire [INV_WIDTH-1:0]   stock_p1,
    output wire [INV_WIDTH-1:0]   stock_p2,
    output wire [INV_WIDTH-1:0]   stock_p3,
    output wire [INV_WIDTH-1:0]   current_stock,
    output wire                   prod_in_stock,
    output wire                   out_of_stock,
    output wire                   low_stock
);

    reg [INV_WIDTH-1:0] r_stock [0:NUM_PRODUCTS-1];

    integer i;

    assign stock_p0 = r_stock[0];
    assign stock_p1 = r_stock[1];
    assign stock_p2 = r_stock[2];
    assign stock_p3 = r_stock[3];

    assign current_stock = (prod_select < NUM_PRODUCTS) ? r_stock[prod_select] : {INV_WIDTH{1'b0}};
    assign prod_in_stock = (current_stock > {INV_WIDTH{1'b0}});
    assign out_of_stock  = (current_stock == {INV_WIDTH{1'b0}});
    assign low_stock     = (current_stock > {INV_WIDTH{1'b0}}) && (current_stock <= LOW_STOCK_LIMIT);

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < NUM_PRODUCTS; i = i + 1) begin
                r_stock[i] <= INITIAL_STOCK;
            end
        end else begin
            if (restock_en) begin
                if (restock_prod_id < NUM_PRODUCTS) begin
                    r_stock[restock_prod_id] <= MAX_STOCK;
                end
            end else if (inventory_dec_en) begin
                if ((dec_prod_id < NUM_PRODUCTS) && (r_stock[dec_prod_id] > {INV_WIDTH{1'b0}})) begin
                    r_stock[dec_prod_id] <= r_stock[dec_prod_id] - 1'b1;
                end
            end
        end
    end

endmodule
