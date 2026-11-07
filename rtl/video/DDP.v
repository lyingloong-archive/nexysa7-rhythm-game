// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  DDP - pixel scaling and colour effects
//
//  Reads the framebuffer at 4x scale and applies the picture-style colour
//  blending. DDP and DST together form the display unit (DU).
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------
module DDP #(
    parameter DW    = 15,
    parameter H_LEN = 200,
    parameter V_LEN = 150
)(
    input               hen,
    input      [1:0]    mode,
    input               ven,
    input               rstn,
    input               pclk,
    input      [11:0]   rdata,
    output reg [11:0]   rgb,
    output reg [DW-1:0] raddr
);

    reg [1:0] sx;       // 4x up-scale counters
    reg [1:0] sy;
    reg [1:0] nsx;
    reg [1:0] nsy;

    reg        deal;
    reg [11:0] last;
    wire [4:0] red, green, blue;

    // Colour mode 1: mix the current pixel with the previous one.
    assign red   = (rdata[11:8] + last[11:8]);
    assign green = (rdata[7:4]  + last[7:4]);
    assign blue  = (rdata[3:0]  + last[3:0]);
    wire [11:0] mix = {red[4:1], green[4:1], blue[4:1]};

    // Colour mode 2: 1-bit per channel plus a 5-bit green tint.
    wire [3:0] red2, green2, blue2;
    assign red2   = (rdata[11:8] + last[11:8]) >>> 1;
    assign green2 = (rdata[7:4]  + last[7:4])  >>> 1;
    assign blue2  = (rdata[3:0]  + last[3:0])  >>> 1;
    wire [11:0] mix2 = {red[1:0], green[4:0], blue[4:0]};
    wire [11:0] mix3 = {red2, green2, blue2};

    always @(*) begin
        sx = nsx;
        sy = nsy;
    end

    initial begin
        raddr = {DW{1'b0}};
        sx    = 2'd0;
        sy    = 2'd0;
        nsx   = 2'd0;
        nsy   = 2'd0;
        rgb   = 12'd0;
        last  = 12'd0;
        deal  = 1'b0;
    end

    always @(posedge pclk) begin   // may lag one cycle; adjust hen/ven if needed
        if (!rstn) begin
            nsx   <= 2'd0;
            nsy   <= 2'd3;
            rgb   <= 12'd0;
            raddr <= {DW{1'b0}};
            last  <= 12'd0;
            deal  <= 1'b0;
        end else if (hen && ven) begin
            case (mode)
                2'd0: rgb <= rdata;
                2'd1: begin rgb <= mix;  last <= mix;  end
                2'd2: begin rgb <= mix2; last <= mix2; end
                2'd3: begin rgb <= mix3; last <= mix3; end
            endcase
            deal <= 1'b1;
            if (sx == 2'b11) begin
                raddr <= raddr + 1'b1;
            end
            nsx <= sx + 2'd1;
        end else if (deal) begin  // end of the visible area
            rgb   <= 12'd0;
            deal  <= 1'b0;
            last  <= 12'd0;
            if (sy != 2'b11) begin
                raddr <= raddr - H_LEN;
            end else if (raddr == H_LEN * V_LEN) begin
                raddr <= {DW{1'b0}};
            end
            nsy <= sy + 2'd1;
        end else begin
            rgb <= 12'd0;
        end
    end
endmodule
