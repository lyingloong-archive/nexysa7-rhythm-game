// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  JK - minimal JK flip-flop
//
//  Single-bit JK flip-flop used as a one-shot / edge latch.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------

module JK(
    input J,K,clk,
    output out
);
reg e;
assign out=e;

initial e = 1'b0;

always @(posedge clk)begin
    if(J)e<=1;
    else if(K)e<=0;
end
endmodule