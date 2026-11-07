// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  STreg - sticky register with write pulse
//
//  Latches a 16-bit value on a write pulse; used for the note time and length.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------


module STreg(
    input clk,
    input rst,
    input we,
    input [15:0]data,
    output [15:0]out
);
reg [15:0] re;
reg modi;

initial begin
    re   = 16'd0;
    modi = 1'b0;
end

always @(posedge clk)begin
    if(we)begin
        if(rst)re<=0;
        if(modi)begin
            re<=data;
            modi<=0;
        end
    end else begin
        if(rst)re<=0;
        modi<=1;
    end
end
assign out=re;
endmodule
