// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  speeder - note speed lookup
//
//  Maps the switch or keyboard speed selection to the clocks-per-percent value used by the timers.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------

module speeder(
    input [2:0] con,
    input clk,
    input [1:0] wspeed, 
    output [31:0] cpp,
    output [7:0] speednote
);
reg [31:0] rcpp;
assign cpp=rcpp;
reg [7:0] rspeed;
assign speednote=rspeed;
reg [2:0] laststate;
initial begin
    laststate=1;
end
always @(posedge clk)begin
    laststate<=con;
    case(con)
        3'd1:begin rcpp<=32'd330169;rspeed<=8'h12;end
        3'd2:begin rcpp<=32'd412711;rspeed<=8'h15;end
        3'd3:begin rcpp<=32'd550282;rspeed<=8'h20;end
        3'd4:begin rcpp<=32'd825423;rspeed<=8'h30;end
        3'd5:begin rcpp<=32'd247626;rspeed<=8'h09;end
        3'd6:begin rcpp<=32'd192598;rspeed<=8'h07;end      
        3'd7:begin rcpp<=32'd137570;rspeed<=8'h05;end
        3'd0:begin
            if(laststate)begin
                rcpp<=32'd275141;rspeed<=8'h10;
            end
            else begin
                case(wspeed)
                    2'd0:;
                    2'd1:if(rspeed>8'h1)begin rcpp<=rcpp-32'd27514;rspeed<=rspeed-((rspeed[3:0]==4'd0)?8'd7:8'd1);end
                    2'd2:if(rspeed<8'h99)
                    begin rcpp<=rcpp+32'd27514;rspeed<=rspeed+((rspeed[3:0]==9)?8'd7:8'd1);end
                    2'd3:begin rcpp<=32'd275141;rspeed<=8'h10;end
                endcase
            end
        end
    endcase
end
endmodule