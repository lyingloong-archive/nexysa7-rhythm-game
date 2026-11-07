// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  keyboard_top - PS/2 receiver wrapper
//
//  Connects the PS/2 frame decoder to the debouncer.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------
module keyboard_top (
    input             CLK100MHZ,
    input             PS2_CLK,
    input             PS2_DATA,
    output     [31:0] keycode,
    output            dee
);

    wire div;
    assign dee = div;

    PS2Receiver keyboard (
        .clk        (CLK100MHZ),
        .kclk       (PS2_CLK),
        .kdata      (PS2_DATA),
        .keycodeout (keycode[31:0]),
        .flagout    (div)
    );

endmodule
