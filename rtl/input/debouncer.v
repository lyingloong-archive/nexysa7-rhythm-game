// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  debouncer - 20-cycle debouncer
//
//  Debounces the PS/2 clock and data lines.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------
module debouncer(
    input             clk,
    input             I0,
    input             I1,
    output reg        O0,
    output reg        O1
);
    reg [4:0] cnt0, cnt1;
    reg       Iv0, Iv1;

    initial begin
        cnt0 = 5'd0;
        cnt1 = 5'd0;
        Iv0  = 1'b0;
        Iv1  = 1'b0;
        O0   = 1'b0;
        O1   = 1'b0;
    end

    // A new level is accepted only after it has been stable for 20 cycles.
    always @(posedge clk) begin
        if (I0 == Iv0) begin
            if (cnt0 == 5'd19) O0 <= I0;
            else               cnt0 <= cnt0 + 5'd1;
        end else begin
            cnt0 <= 5'd0;
            Iv0  <= I0;
        end

        if (I1 == Iv1) begin
            if (cnt1 == 5'd19) O1 <= I1;
            else               cnt1 <= cnt1 + 5'd1;
        end else begin
            cnt1 <= 5'd0;
            Iv1  <= I1;
        end
    end
endmodule
