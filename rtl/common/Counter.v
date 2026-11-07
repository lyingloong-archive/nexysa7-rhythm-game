// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  Counter - two-level counter
//
//  Divides the clock by a compile-time WIDTH and counts up to MAX.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------

module Counter #(
    parameter   WIDTH=32'd1,
    parameter   MAX=32'd100000
)(
    input                   clk,
    input                   rst,
    output       [31:0]     out
);

reg [31:0] counter;
reg [31:0] puter;
initial begin
    puter = 0;
    counter=0;
end
always @(posedge clk) begin
    if (rst) begin
        counter <= 0;
        puter <= 0;
    end else begin
        if (counter >= WIDTH-1) begin
            counter <= 0;
            if(puter == MAX-1) puter <= 0;
            else puter <= puter + 32'd1;
        end else
            counter <= counter + 32'd1;
    end
end
assign out=puter;
endmodule