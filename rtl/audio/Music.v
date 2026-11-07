// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  Music - song player
//
//  Reads the chart ROM, advances on the song timer and drives the tone generator and the audio amplifier enable.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------

module Music(
    input [31:0]WIDTH,
    input clk,
    input startmusic,
    input rst,
    input endmusic,
    input wrongmusic,
    output pwm,
    output sd,
    output [31:0] debuger
);

reg beginmusic;
wire [31:0] lent;
CounterW #(.MAX(32'd1000000)) cnter3(
    .WIDTH(WIDTH),
    .clk(clk),
    .rst(rst||beginmusic),
    .out(lent)
);
wire [31:0] go;
CounterW #(.MAX(32'd10000)) cnter4(
    .WIDTH(32'd6264000),
    .clk(clk),
    .rst(rst||startmusic),
    .out(go)
);
localparam IDLE=0;
localparam WAIT=1;
reg [3:0] send;
reg run;
reg waiting;
reg [1:0] state;
reg [8:0] addr;
wire [8:0]waddr=addr;
wire [23:0]data;
reg cache;
initial begin
    state=IDLE;
    cache=0;
    beginmusic=0;
    run=0;
end
// Note table (Xilinx memory IP, not part of this repository):
// data[23:4] = note start time in units of WIDTH clocks, data[3:0] = note number.
memmusic musicer (
  .a(waddr),     
  .spo(data)  
);
always @(posedge clk) begin
    case(state)
        IDLE:begin
            cache<=1;
            send<=0;
            if(waiting)begin
                if(go>=32'd1)begin
                    waiting<=0;
                    beginmusic<=1;
                    state<=WAIT;
                end
            end else if(startmusic)begin
                addr<=0;
                waiting<=1;
            end
        end
        WAIT:begin
            beginmusic<=0;
            if(rst)begin
                state<=IDLE;
            end else if(endmusic)begin
                state<=IDLE;
            end else if(wrongmusic)begin
                state<=IDLE;
            end else if(data[23:4]==lent)begin
                cache<=1;
                send<=data[3:0];
                addr<=addr+8'd1;
            end else begin
                run<=cache;
                cache<=0;
            end 
        end
    endcase
end
wire pwmww,sdww;
assign pwm=((state==WAIT)?pwmww:0);
assign sd=((state==WAIT)?sdww:0);
audio audioer(
    .clk(clk),
    .rstn(~rst),
    .note_en(run),
    .note(send[3:0]),
    .pwm(pwmww),
    .sd(sdww)
);
assign debuger={send[3:0],addr[3:0],state,run,startmusic,endmusic,20'd0};
endmodule