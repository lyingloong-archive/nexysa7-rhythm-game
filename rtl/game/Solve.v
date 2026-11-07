// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  Solve - note scheduler and judging state machine
//
//  Walks the note chart, times key presses against the current note, drives the score and exposes the HUD values used by the renderer.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------

module Solve#(
    parameter Y=150,
    parameter X=200
)(
    input clk,
    input halt,
    input prepare,
    input start,
    input next,
    input switcher,
    input sw2,
    input auto,
    input keep,
    input [15:0] length,
    input [15:0] now,
    input [4:0] debug,
    output [15:0] dataput,          // HUD payload for the LEDs
    output [31:0] dataput2,         // HUD payload for the 7-segment display
    output wrong,
    output solved,
    output fakeclick,
    output [31:0] score,
    output signed [15:0] wwmodi, 
    output ready,
    output wfresh,
    output [11:0] wcolorp,
    output [17:0] wBLOn,
    output nnote0,
    output [15:0] wnotex,wnotey,
    output [15:0] wperc,
    output endpass
);
localparam RED12 = 12'hf00;     // 4 bits per channel
localparam BLUE12 = 12'h00f;     // 4 bits per channel
reg [15:0] alldev;
reg [15:0] nnote;
reg [15:0] snote;
reg [15:0] notex,notey,noted,notel;
reg anti;
wire [15:0] per=noted+(anti?now:16'd360-now);
wire [15:0] perc=(per>=16'd360)?(per-16'd360):per;
assign wperc=perc;
reg dealtadd;
reg invalidadd;
reg fclick;
reg [31:0] BLOR0=0;
// The first 20 words of the track table are segment headers, not notes.
localparam BLOR=20;
reg [17:0] BLOn=0;
reg fresh;
reg [3:0] state;
localparam IDLE=10;
localparam WAITSTART=1;
localparam READNOTE=2;
localparam READINGNOTE=3;
localparam README=4;
localparam READINGSWI=5;
localparam WAIT=6;
localparam WAITJUDGE=7;
localparam CACHEDEV=8;
localparam PASS=14;
localparam WRONG=15;
localparam XY=X*Y;
reg [15:0] cnttt;
reg signed [15:0] modi;
reg beginscore;
reg preparing;
reg judgestart;

initial begin
    state=IDLE;fclick=0;
end
wire addsign;
wire [15:0] outnow,outlength;
JK regjk(
    .clk(clk),
    .J(next),
    .K(dealtadd||(state==IDLE)),
    .out(addsign)
);
STreg regtime(
    .clk(clk),
    .rst(prepare),
    .we(next),
    .data(now),
    .out(outnow)
);
STreg reglength(
    .clk(clk),
    .rst(prepare),
    .we(next),
    .data(length),
    .out(outlength)
);
wire [2:0] jures;
wire AC=~(jures[1]&jures[0]);
wire judgeready;
wire signed [15:0] wmodi;
assign wwmodi=modi;
Judge judger(
    .clk(clk),
    .start(judgestart),
    .ready(judgeready),
    .now(outnow),
    .fac(alldev),
    .modi(wmodi),
    .out(jures)
);
Score #(.AC(16'h100)) scorer(
    .clk(clk),
    .rst(preparing),
    .cal(beginscore),
    .dev(wmodi),
    .result(jures),
    .out(score)
);
reg [9:0] aroad;
reg [15:0] till;
wire [63:0] droad;
// Track/note table (Xilinx memory IP, not part of this repository).
memroad memroad(
  .a(aroad),      // input wire [9 : 0] a
  .d(64'd0),      // input wire [63 : 0] d
  .clk(clk),      // input wire clk
  .we(1'b0),      // input wire we
  .spo(droad)     // output wire [63 : 0] spo
);
reg [63:0] ssav;
reg [11:0] colorp;
wire [15:0] taskp=notel+16'd80+modi;
wire [15:0] taskri=notel+modi;
reg [3:0] waitr;
wire [15:0] tasklow=((notel+modi+16'd90)>16'd180)?(notel+modi-16'd90):0;
assign ready=(state==WAITSTART);
assign wrong=(state==WRONG);
assign wnotex=notex;
assign wnotey=notey;
assign solved=dealtadd&&(!invalidadd);
assign fakeclick=fclick;
assign wBLOn=BLOn;
assign wfresh=fresh;
assign wcolorp=colorp;
assign nnote0=nnote[0];

assign endpass=(state==PASS);
always @(posedge clk) begin
    case(state)
        IDLE:begin
            if(prepare)begin
                fresh<=0;
                nnote<=0;
                modi<=0;
                cnttt<=0;
                waitr<=15;
                preparing<=1;
                snote<=0;
                alldev<=0;
                BLOn<=0;
                BLOR0<=0;
                state<=READNOTE;
            end
        end
        WAITSTART:begin
            preparing<=0;
            if(start)begin
                fresh<=1;
                state<=WAIT;
            end
        end
        READNOTE:begin
            fresh<=0;
            dealtadd<=0;
            beginscore<=0;
            cnttt<=0;
            if(snote==nnote)begin
                aroad<=BLOR0;
                BLOR0<=BLOR0+16'd1;
            end else begin
                aroad<=nnote+BLOR;
            end 
            state<=README;
        end
        READINGSWI:begin 
            fresh<=1;
            snote<=ssav[15:0];
            aroad<=nnote+BLOR;
            state<=README;
            if(nnote!=0)BLOn<=BLOn+XY;
        end
        READINGNOTE:begin
            if(ssav==0)begin
                state<=PASS;
            end else begin
                anti<=ssav[31];              // direction of the track at this note
                till<={1'b0,ssav[30:16]};
                notel<={1'b0,ssav[30:16]};
                noted<=ssav[15:0];
                notex<=ssav[63:48];
                notey<=ssav[47:32];
                if(ssav[30:16]==0)state<=PASS;
                else state<=CACHEDEV;
            end
        end
        README:begin
            fresh<=0;
            state<=(aroad<BLOR)?READINGSWI:READINGNOTE;
            ssav<=droad;
        end
        CACHEDEV: begin
            fresh<=0;
            dealtadd<=0;
            invalidadd<=0;
            fclick<=0;
            if(till!=0)begin
                till<=0;
                alldev<=alldev+till;
            end else if(alldev>=16'd360)begin
                alldev<=alldev-16'd360;
            end else if(preparing)begin
                state<=WAITSTART;
            end else if(waitr!=4'd15)begin
                waitr<=waitr+4'd1;
            end else state<=WAIT;
        end
        WAIT: begin
            fresh<=0;
            if(debug[4]&&nnote<(debug[3:0]<<3))begin
                nnote<=nnote+1;
                state<=READNOTE;
                fresh<=1;
            end else if(halt)begin
                state<=IDLE;
            end else if(addsign)begin
                if(outlength+16'd150<=notel)begin
                    dealtadd<=1;
                    if(keep||length<=tasklow)begin
                        state<=CACHEDEV;
                        invalidadd<=1;
                    end
                    else begin
                        state<=WAITJUDGE;
                        judgestart<=1;
                        dealtadd<=1;
                    end 
                end else if(length<=tasklow)begin
                    state<=CACHEDEV;
                    dealtadd<=1;
                    invalidadd<=1;
                end else begin
                    state<=WAITJUDGE;
                    judgestart<=1;
                    dealtadd<=1;
                end 
            end else if(length>=taskp)begin
                if(keep)begin
                    state<=CACHEDEV;
                    waitr<=4'd1;
                    fclick<=1;
                end
                else begin
                    modi<=0-16'sd80;
                    colorp<=12'h22f;
                    state<=WRONG;
                end
            end else if(auto)begin
                if(length==taskri)begin
                    state<=CACHEDEV;
                    waitr<=4'd1;
                    fclick<=1;
                end
            end
        end
        WAITJUDGE:begin
            judgestart<=0;
            if(judgeready)begin
                case(jures)
                    3'd4:colorp<=12'h2f0;
                    3'd5:colorp<=12'hff0;
                    3'd6:colorp<=12'hf80;
                    3'd7:colorp<=12'hf00;
                    3'd0:colorp<=12'h0f2;
                    3'd1:colorp<=12'h0ff;
                    3'd2:colorp<=12'h08f;
                    3'd3:colorp<=12'h22f;
                endcase
                if((!AC)&&(!keep))begin
                    modi<=wmodi;
                    state<=WRONG;
                end else begin
                    modi<=wmodi;
                    beginscore<=1;
                    nnote<=nnote+1;
                    state<=READNOTE;
                end
            end
        end
        WRONG:begin
            if(halt)begin
                state<=IDLE;
            end
        end
        PASS:begin 
            if(halt)begin
                state<=IDLE;
            end
        end
        default:;
    endcase
end
assign dataput=switcher?(sw2?perc[15:0]:now[15:0]):{snote[3:0],waitr[3:0],state[3:0],cnttt[3:0]};
wire [31:0] putdata1={colorp,1'd0,jures,score[31:16]};
wire [31:0] putdata2={modi[15:0],wmodi[15:0]};
wire [31:0] dataput22=switcher?putdata1:putdata2;
wire [31:0] putdata3=switcher?{modi,-modi}:{-modi,modi};
assign dataput2=sw2?putdata3:dataput22;
endmodule