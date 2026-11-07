// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  DU - video output unit
//
//  VGA timing generator, 4x pixel scaler and the read port of the framebuffer.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------
//
// NOTE: `memvmap` is a Xilinx dual-port RAM IP (32768 x 12, initialised with
// data/coe/beginphoto.coe). The IP core is not part of this repository, see
// docs/rebuilding.md.
module DU(
    input             rst,
    input             clk,
    input      [1:0]  mode,
    input      [11:0] inrgb,
    input             we,
    input      [14:0] addr,
    output     [11:0] rgb,
    output            VGA_HS,
    output            VGA_VS
);

    // 100 MHz -> 50 MHz pixel clock.
    reg pclk;
    initial pclk = 1'b0;
    always @(posedge clk) pclk <= ~pclk;

    wire hen, ven;

    DST vga_timing(
        .rstn ( ~rst ),
        .pclk ( pclk ),
        .hen  ( hen ),
        .ven  ( ven ),
        .vs   ( VGA_VS ),
        .hs   ( VGA_HS )
    );

    wire [11:0] rdata;
    wire [14:0] raddr;

    DDP #(.DW(32'd15), .H_LEN(32'd200), .V_LEN(32'd150)) ddp(
        .hen   ( hen ),
        .ven   ( ven ),
        .rstn  ( ~rst ),
        .pclk  ( pclk ),
        .mode  ( mode ),
        .rdata ( rdata ),
        .raddr ( raddr ),
        .rgb   ( rgb )
    );

    // Framebuffer: 32768 x 12 dual-port RAM, one write port for the renderer
    // and one read port for the VGA scanner.
    memvmap mem (
        .a    ( addr ),
        .d    ( inrgb ),
        .dpra ( raddr ),
        .clk  ( clk ),
        .we   ( we ),
        .dpo  ( rdata )
    );

endmodule
