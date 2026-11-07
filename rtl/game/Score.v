// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  Score - decimal score accumulator
//
//  Adds the judgement value to the score through a packed-BCD (8421) adder so the display stays decimal.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------

module Score#(
    parameter AC=32'h100
)(
    input clk,
    input rst,
    input cal,
    input [2:0] result,
    input signed [15:0] dev,
    output [31:0] out
);
wire [31:0] value;
wire ok;
reg [31:0] mid;
reg [31:0] score;
wire signed [15:0] nmodi=-dev;
reg start;
// AC is the perfect-hit score (0x100 = 256). `mid` holds the points for the
// current hit and the packed-BCD adder accumulates it into `score`.
Adder8421 adder(
    .clk(clk),
    .rst(rst),
    .c(value),
    .start(start),
    .ready(ok),
    .a(score),
    .b(mid)
);
reg state;
initial begin
    state=0;start=0;
    score=0;
end
always @(posedge clk)begin
    if(rst)score<=0;
    else begin 
        if(state)begin
            start<=0;
            if(ok)begin
                state<=0;
                score<=value;
            end
        end else begin   
            if(cal)begin
                
                state<=1;
                start<=1;
                if(result[1:0]==0)begin
                    mid<=AC;
                end else if(result[1:0]==3)begin
                    mid<=0;
                end else if(dev>=16'sh0)begin
                    if(result[1])begin
                        mid<=32'h89-{nmodi[5:3],1'd0,nmodi[2:0]};
                    end else begin
                        mid<=32'h99-{nmodi[5:3],1'd0,nmodi[2:0]};
                    end
                end else begin
                    if(result[1])begin
                        mid<=32'h89-{dev[5:3],1'd0,dev[2:0]};
                    end else begin
                        mid<=32'h99-{dev[5:3],1'd0,dev[2:0]};
                    end
                end
            end
        end
    end
end
assign out=score;
endmodule
