// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  transer - binary to packed BCD
//
//  Converts an 8-bit binary value to three packed 8421 digits for the 7-segment display.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------

module transer(
    input [7:0] dev,
    input clk,
    output [11:0] put
);
reg [11:0] ans;
reg [11:0] data;
reg [7:0] lasdev;
assign put=ans;
localparam IDLE=0;
localparam PRE=1;
localparam DEAL1=2;
localparam DEAL2=3;
reg [1:0] state;
initial begin
    ans    = 12'd0;
    data   = 12'd0;
    lasdev = 8'd0;
    state  = IDLE;
end
always @(posedge clk)begin
    case(state)
        IDLE:begin
            if(lasdev!=dev)begin
                lasdev<=dev;
                state<=PRE;
            end
        end
        PRE:begin
            case(dev[7:4])
                4'd0:data<=12'h0;
                4'd1:data<=12'h16;
                4'd2:data<=12'h32;
                4'd3:data<=12'h48;
                4'd4:data<=12'h64;
                4'd5:data<=12'h80;
                4'd6:data<=12'h96;
                4'd7:data<=12'h112;
                4'd8:data<=12'h128;
                4'd9:data<=12'h144;
                4'd10:data<=12'h160;
                4'd11:data<=12'h176;
                4'd12:data<=12'h192;
                4'd13:data<=12'h208;
                4'd14:data<=12'h224;
                4'd15:data<=12'h240;
            endcase
            state<=DEAL1;
        end
        DEAL1:begin
            if(data[3:0]+dev[3:0]>=4'd10)data<=data+dev[3:0]+6;
            else data<=data+dev[3:0];
            state<=DEAL2;
        end
        DEAL2:begin
            if(data[7:4]>=4'd10)ans<=data+12'h60;
            else ans<=data;
            state<=IDLE;
        end
    endcase
end
endmodule
