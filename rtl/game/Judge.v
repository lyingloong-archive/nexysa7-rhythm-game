// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  Judge - timing to judgement converter
//
//  Turns the angular error between a key press and the target note into one of eight judgement levels.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------

module Judge(
    input clk,
    input start,
    input [15:0] now,
    input [15:0] fac,
    output [2:0] out,
    output signed [15:0] modi,
    output ready
);
reg [1:0] state;
reg [2:0] res;
reg signed [15:0] dec;
reg signed [15:0] rmodi;
assign modi=rmodi;
reg resd;
assign out=res;
initial begin
    state=0;resd=0;
end
assign ready=resd;
// The timing error is normalised to 0..360 degrees. Levels 4..7 are early hits
// (4 is the closest) and 3..0 are late hits (3 is the closest); Solve maps each
// level to a HUD colour.
always @ (posedge clk) begin
    case(state)
        2'd0:begin
            resd<=0;
            if(start)begin
                state<=1;
                dec<=$signed(fac)-$signed(now);
            end
        end
        2'd1:begin
            rmodi<=dec;
            dec<=(dec>16'd360)?dec+16'd360:dec;
            state<=2;
        end
        2'd2:begin
            state<=3;
            if(rmodi<16'd360&&rmodi>=16'd180)begin
                rmodi<=rmodi-16'd360;
            end else if(rmodi>=16'd360&&rmodi<=16'hff4B)begin
                rmodi<=rmodi+16'd360;
            end
            if(dec<16'd180)begin
                if(dec>16'd45)begin
                    if(dec>16'd60)res<=3'b111;
                    else res<=3'b110;
                end else begin
                    if(dec>16'd30)res<=3'b101;
                    else res<=3'b100;
                end 
            end else begin
                if(dec<16'd315)begin
                    if(dec<16'd300)res<=3'b011;
                    else res<=3'b010;
                end else begin
                    if(dec<16'd330)res<=3'b001;
                    else res<=3'b000;
                end 
            end
        end
        2'd3:begin
            state<=0;
            resd<=1;
        end
    endcase
end
endmodule