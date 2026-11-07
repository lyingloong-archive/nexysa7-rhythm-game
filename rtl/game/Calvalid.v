// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  Calvalid - pipelined circle hit test
//
//  Computes (x-dx)^2 + (y-dy)^2 <= r2 over three cycles and reports the result together with a ready flag.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------

module Calvalid(
    input clk,
    input start,
    input [15:0] r2,
    input signed [15:0] x,dx,
    input signed [15:0] y,dy,
    output valid,
    output ready
);
reg [1:0] state;
reg res;
reg val;
reg signed [31:0] xx;
reg signed [31:0] yy;
initial begin
    state=0;val=0;
end
assign ready=res;
assign valid=val;
always @(posedge clk)begin
    case(state)
        2'd1:begin
            xx<=xx*xx;
            yy<=yy*yy;
            state<=2'd2;
        end 
        2'd2:begin
            val<=(r2>=(xx+yy));
            res<=1;
            state<=2'd0;
        end
        2'd0:begin
            res<=0;
            if(start)begin
                xx<=x-dx;
                yy<=y-dy;
                state<=2'd1;
            end
        end
    endcase
end
endmodule
