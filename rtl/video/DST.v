// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  DST - VGA sync and countdown timers
//
//  Counts down through the sync/back-porch/active/front-porch phases of one
//  line and one frame, and produces the h/v sync and enable signals.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------

// Reloadable down-counter: counts from the reload value d down to zero, then
// reloads. A single-cycle pulse of `ce` starts one decrement.
module CntS #(
    parameter               WIDTH               = 16,
    parameter               RST_VLU             = 0
)(
    input                   [ 0 : 0]            clk,
    input                   [ 0 : 0]            rstn,   // reset, active low
    input                   [WIDTH-1:0]         d,      // reload value
    input                   [ 0 : 0]            ce,     // count enable
    output      reg         [WIDTH-1:0]         q
);
    initial begin
        q = 0;
    end

    always @(posedge clk) begin
        if (!rstn)
            q <= RST_VLU;
        else if (ce) begin
            if (q == 0)
                q <= d;
            else
                q <= q - 1;
        end
    end
endmodule

// VGA timing generator for 200x150 active pixels scaled 4x (800x600 output).
// The counter reload values below are one less than the phase length, because
// CntS spends one cycle at zero before reloading.
module DST (
    input                   [ 0 : 0]            rstn,
    input                   [ 0 : 0]            pclk,

    output      reg         [ 0 : 0]            hen,        // horizontal display enable
    output      reg         [ 0 : 0]            ven,        // vertical display enable
    output      reg         [ 0 : 0]            hs,         // horizontal sync
    output      reg         [ 0 : 0]            vs          // vertical sync
);

    localparam HSW_t    = 119;   // horizontal sync
    localparam HBP_t    = 63;    // horizontal back porch
    localparam HEN_t    = 799;   // horizontal active
    localparam HFP_t    = 55;    // horizontal front porch

    localparam VSW_t    = 5;     // vertical sync
    localparam VBP_t    = 22;    // vertical back porch
    localparam VEN_t    = 599;   // vertical active
    localparam VFP_t    = 36;    // vertical front porch

    // TODO: VBP_t / VEN_t / VFP_t were tuned empirically on the lab monitor;
    // they are kept as-is because the original bitstream is the reference.
    localparam SW       = 2'b00;
    localparam BP       = 2'b01;
    localparam EN       = 2'b10;
    localparam FP       = 2'b11;

    reg         [ 0 : 0]    ce_v;

    reg         [ 1 : 0]    h_state;
    reg         [ 1 : 0]    v_state;

    reg         [15 : 0]    d_h;
    reg         [15 : 0]    d_v;

    wire        [15 : 0]    q_h;
    wire        [15 : 0]    q_v;

    initial begin
        h_state = SW;
        v_state = SW;
        d_h     = 16'd0;
        d_v     = 16'd0;
        ce_v    = 1'b0;
    end

    CntS #(16, HSW_t) hcnt(          // one pixel per clock
        .clk        (pclk),
        .rstn       (rstn),
        .d          (d_h),
        .ce         (1'b1),
        .q          (q_h)
    );

    CntS #(16, VSW_t) vcnt(          // one line per horizontal wrap
        .clk        (pclk),
        .rstn       (rstn),
        .d          (d_v),
        .ce         (ce_v),
        .q          (q_v)
    );

    // Phase decode. The reload value for the current phase is selected
    // combinationally; the counter reloads it when its own count reaches zero.
    always @(*) begin
        case (h_state)
            SW: begin
                d_h = HBP_t;  hs = 1; hen = 0;
            end
            BP: begin
                d_h = HEN_t;  hs = 0; hen = 0;
            end
            EN: begin
                d_h = HFP_t;  hs = 0; hen = 1;
            end
            FP: begin
                d_h = HSW_t;  hs = 0; hen = 0;
            end
        endcase
        case (v_state)
            SW: begin
                d_v = VBP_t;  vs = 1; ven = 0;
            end
            BP: begin
                d_v = VEN_t;  vs = 0; ven = 0;
            end
            EN: begin
                d_v = VFP_t;  vs = 0; ven = 1;
            end
            FP: begin
                d_v = VSW_t;  vs = 0; ven = 0;
            end
        endcase
    end

    always @(posedge pclk) begin
        if (!rstn) begin
            h_state <= SW;
            v_state <= SW;
            ce_v    <= 1'b0;
        end else begin
            if (q_h == 0) begin
                h_state <= h_state + 2'b01;
                if (h_state == FP) begin
                    ce_v <= 1'b0;
                    if (q_v == 0)
                        v_state <= v_state + 2'b01;
                end else begin
                    ce_v <= 1'b0;
                end
            end else if (q_h == 1) begin
                if (h_state == FP)
                    ce_v <= 1'b1;
                else
                    ce_v <= 1'b0;
            end else begin
                ce_v <= 1'b0;
            end
        end
    end
endmodule
