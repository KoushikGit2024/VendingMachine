// ============================================================================
// Module: online_payment_interface
// Description: Synchronous online payment authorization bridge and watchdog
//              timer for the Digital Vending Machine controller.
// Standard: IEEE 1364-2001 (Verilog-2001)
// ============================================================================

`timescale 1ns / 1ps

module online_payment_interface #(
    parameter MONEY_WIDTH           = 16,
    parameter ONLINE_TIMEOUT_CYCLES = 1000,
    parameter ONLINE_TIMER_WIDTH    = 10
)(
    input  wire                   clk,
    input  wire                   rst,

    input  wire                   online_req_active,

    input  wire [MONEY_WIDTH-1:0] prod_price,
    input  wire [MONEY_WIDTH-1:0] accum_balance,

    output reg                    online_pay_req,
    output reg  [MONEY_WIDTH-1:0] online_pay_amount,

    input  wire                   online_pay_ack,
    input  wire [1:0]             online_pay_status,

    output reg                    online_pay_approved,
    output reg                    online_pay_declined,
    output reg                    online_pay_timeout
);

    reg [ONLINE_TIMER_WIDTH-1:0] r_timer;
    reg                          r_active_d;

    always @(posedge clk) begin
        if (rst) begin
            online_pay_req      <= 1'b0;
            online_pay_amount   <= {MONEY_WIDTH{1'b0}};
            online_pay_approved <= 1'b0;
            online_pay_declined <= 1'b0;
            online_pay_timeout  <= 1'b0;
            r_timer             <= {ONLINE_TIMER_WIDTH{1'b0}};
            r_active_d          <= 1'b0;
        end else begin
            r_active_d <= online_req_active;

            if (!online_req_active) begin
                online_pay_req      <= 1'b0;
                online_pay_amount   <= {MONEY_WIDTH{1'b0}};
                online_pay_approved <= 1'b0;
                online_pay_declined <= 1'b0;
                online_pay_timeout  <= 1'b0;
                r_timer             <= {ONLINE_TIMER_WIDTH{1'b0}};
            end else begin
                // Trigger/activation edge when entering online wait state
                if (!r_active_d && online_req_active) begin
                    online_pay_req <= 1'b1;
                    if (prod_price > accum_balance) begin
                        online_pay_amount <= prod_price - accum_balance;
                    end else begin
                        online_pay_amount <= {MONEY_WIDTH{1'b0}};
                    end
                    online_pay_approved <= 1'b0;
                    online_pay_declined <= 1'b0;
                    online_pay_timeout  <= 1'b0;
                    r_timer             <= {ONLINE_TIMER_WIDTH{1'b0}};
                end else if (online_pay_req) begin
                    if (online_pay_ack) begin
                        online_pay_req <= 1'b0;
                        if (online_pay_status == 2'b01) begin
                            online_pay_approved <= 1'b1;
                            online_pay_declined <= 1'b0;
                        end else begin
                            online_pay_approved <= 1'b0;
                            online_pay_declined <= 1'b1;
                        end
                        online_pay_timeout <= 1'b0;
                    end else begin
                        if (r_timer >= (ONLINE_TIMEOUT_CYCLES - 1)) begin
                            online_pay_req      <= 1'b0;
                            online_pay_approved <= 1'b0;
                            online_pay_declined <= 1'b0;
                            online_pay_timeout  <= 1'b1;
                        end else begin
                            r_timer <= r_timer + 1'b1;
                        end
                    end
                end
            end
        end
    end

endmodule
