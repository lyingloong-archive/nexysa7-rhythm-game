// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  pwm_gen - PWM carrier generator
//
//  Generates the PWM carrier for the on-board audio amplifier.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------

`timescale 1ns / 1ps

// Duty cycle = h_time / period; the high time is swept by the caller to make
// a simple envelope.
module pwm_gen (
    input      [11:0] period,   // PWM period, in clock cycles
    input      [11:0] h_time,   // high time, in clock cycles
    input             clk,
    output reg        wave,     // PWM output
    output reg        pulse     // one-cycle pulse at the end of each period
);
    reg [11:0] cnt=0;
    always @(posedge clk) begin
        cnt <= cnt+1;
        pulse <= 0;
        if(cnt>period) begin
            cnt <= 0;
            pulse <= 1;
        end else if(cnt<{h_time>>2}) begin // 3/4 of the high time -> lower volume
            wave <= 1;
        end else begin
            wave <= 0;
        end
    end
endmodule