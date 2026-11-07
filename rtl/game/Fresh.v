// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  Fresh - frame composer
//
//  Scans the 200x150 canvas, blends the background, notes and HUD, and writes the result into the video RAM through the DU write port.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------

module Fresh#(
    parameter Y=150,
    parameter X=200
)(
    input clk,
    input fresh,
    input [15:0] perc,
    input auto,keep,
    input [15:0] notex,
    input signed [15:0] wmodi,
    input [15:0] notey,
    input [31:0] score,
    input [17:0] BLOn,
    input [11:0] colorp,
    input notecolor,
    input wastate,
    input [7:0] speed,
    output [14:0] madd,
    output vwe,
    output [11:0] prgb
);
localparam RED12 = 12'hf00;     // 4 bits per channel
localparam BLUE12 = 12'h00f;     // 4 bits per channel
localparam GREEN12 = 12'h0f0; 
localparam BLUE126 = 12'h66f;     // 4 bits per channel
reg [11:0]rgb;
assign prgb=rgb;
reg [15:0] x;
reg [15:0] y;
// Hit radii (in pixels) used by the note hit tests. The background changes
// every 30000 pixels, which selects a slightly different track radius.
wire [15:0] r2 = (BLOn == 18'd30000) ? 16'd26 : 16'd37;
localparam E  = 16'd32;   // OK zone
localparam JR = 16'd75;   // trigger zone
localparam ALL=16'd312;
reg [31:0] addr;
assign madd=addr[14:0];
reg [2:0] state;
reg [1:0] readed;
localparam SWITCH=0;
localparam RUN=1;
localparam README=2;
localparam WRITEME=3;

reg [15:0] cnttt;
assign vwe=(state==WRITEME);
wire [11:0] mainc=notecolor?RED12:BLUE12;
wire [11:0] subc=notecolor?BLUE12:RED12;

reg loading;
reg startcal;
wire valE,valErd,valr,valrrd,valR,valRrd,valJR,valJRrd;
wire finishcal=valJRrd&valErd&valrrd&valRrd;
Calvalid calvJR(
    .start(startcal),
    .clk(clk),
    .x(x),
    .dx(notex),
    .y(y),
    .dy(notey),
    .r2(JR*JR),
    .valid(valJR),
    .ready(valJRrd)
);
Calvalid calvE(
    .start(startcal),
    .clk(clk),
    .x(x),
    .dx(notex),
    .y(y),
    .dy(notey),
    .r2(E*E),
    .valid(valE),
    .ready(valErd)
);
Calvalid calvr(
    .start(startcal),
    .clk(clk),
    .x(x),
    .dx(notex),
    .y(y),
    .dy(notey),
    .r2(r2),
    .valid(valr),
    .ready(valrrd)
);
wire signed[15:0] dxdroad,dydroad;
reg signed [15:0] indx,indy;
Calvalid calvR(
    .start(startcal),
    .clk(clk),
    .x(x),
    .dx(indx),
    .y(y),
    .dy(indy),
    .r2(r2),
    .valid(valR),
    .ready(valRrd)
);
Getsin gets(
    .clk(clk),
    .now(perc),
    .dx(dxdroad),
    .dy(dydroad)
);

wire needspeed=speed!=8'h10;
wire [11:0] speedcolor=((speed>8'h10)?BLUE126:RED12);
wire neg=wmodi>16'h1000;
wire [15:0] admodi=neg?-wmodi:wmodi;
wire yesspeed,yesscore,yesscore2;
Getdot gets1(
    .clk(clk),
    .x(x-((x>=42)?8'd37:8'd33)),
    .y(y-16'd2),
    .score({12'd0,speed,12'd0}),
    .valid(yesspeed)
);
Getdot gets2(
    .clk(clk),
    .x(x-8'd136),
    .y(y-16'd2),
    .score(score),
    .valid(yesscore)
);

wire [11:0] putmodi;
Getdot gets3(
    .clk(clk),
    .x(x-8'd83),
    .y(y-16'd2),
    .score({12'd0,putmodi,8'd0}),
    .valid(yesscore2)
);  
transer get8421(
    .clk(clk),
    .dev(admodi[7:0]),
    .put(putmodi)
);
wire [11:0] dmap;
wire [17:0] sendram=addr[17:0]+BLOn;
// Background ROM (Xilinx block-memory IP, not part of this repository).
mammap memmap (
  .clka(clk),    // input wire clka
  .addra(sendram),  // input wire [17 : 0] addra
  .douta(dmap)  // output wire [11 : 0] douta
);
// HUD hit zones (screen coordinates): pause button, speed buttons, dots,
// score box and the "state" box in the bottom right corner.
wire gopan;
reg [15:0] lax,lay;
assign gopan=(x>=16'd83&&x<=16'd109&&y<=16'd13&&y>=16'd2);
wire gospeed;
assign gospeed=(((x>=16'd33&&x<=16'd41)||(x>=16'd45&&x<=16'd53))&&y<=16'd13&&y>=16'd2);
wire godot;
assign godot=(x==16'd43||x==16'd44)&&(y==16'd12||y==16'd13);
wire goscore;
assign goscore=(x>=16'd136&&x<=16'd180&&y<=16'd13&&y>=16'd2);
wire gostate;
assign gostate=(x>=16'd173&&x<=16'd185&&y<=16'd145&&y>=16'd133);
wire need;
reg done;
initial begin
    state=SWITCH;x=0;y=0;cnttt=0;loading=1;addr=0;done=0;
end
JK needfresh(
    .clk(clk),
    .J(fresh),
    .K(done),
    .out(need)
);
always @(posedge clk) begin
    case(state)
        SWITCH:begin
            if(need)begin
                loading<=1;
                cnttt<=0;
                done<=1;
            end else begin
                done<=0;
                indx<=$signed(notex)+dxdroad;
                indy<=$signed(notey)-dydroad;
                if(x==X-1) begin
                    x<=0;
                    cnttt<=cnttt+1;
                    if(y==Y-1) begin     
                        y<=0;addr<=0;
                    end
                    else begin
                        y<=y+16'd1;
                        addr<=addr+32'd1;
                    end
                end else begin
                    if(lax!=notex||lay!=notey)begin
                        lax<=notex;
                        lay<=notey;
                        cnttt<=0;
                    end
                    x<=x+16'd1;
                    addr<=addr+32'd1;
                end
                startcal<=1;
                state<=RUN;
            end
        end
        RUN:begin
            startcal<=0;
            if(finishcal)begin
                if(gostate&(auto|keep))begin
                    if(auto)rgb<=RED12;
                    else rgb<=GREEN12;
                    state<=WRITEME;
                end else if(gostate)begin
                    state<=README;
                end else if(goscore)begin
                    if(cnttt<=ALL||loading)begin
                        if(yesscore)begin
                            rgb<=colorp;
                            state<=WRITEME;
                        end else if(wastate)begin
                                rgb<=~colorp;
                                state<=WRITEME;
                        end else state<=README;
                    end else state<=SWITCH;
                end else if(gospeed)begin
                    if(yesspeed&&needspeed)begin
                        rgb<=speedcolor;
                        state<=WRITEME;
                    end else state<=README;
                end else if(godot)begin
                    if(needspeed)begin
                        rgb<=speedcolor;
                        state<=WRITEME;
                    end else state<=README;
                end else if(gopan) begin
                    if(cnttt<=ALL||loading)begin
                        if(yesscore2)begin
                            if(neg)rgb<=BLUE126;
                            else rgb<=RED12;
                            state<=WRITEME; 
                        end else if(wastate)begin
                            if(~neg)rgb<=BLUE126;
                            else rgb<=RED12;
                            state<=WRITEME;
                        end else state<=README;
                    end else state<=SWITCH;
                end else if(valr)begin
                    state<=WRITEME;
                    rgb<=mainc;
                end else if((cnttt<=ALL||valE)&&valJR)begin
                    if(valR)begin
                        state<=WRITEME;
                        rgb<=subc;
                    end else begin
                        state<=README;
                    end
                end else if(loading)begin
                    if(cnttt>ALL)loading<=0;
                    state<=README;
                end else begin
                    state<=SWITCH;
                end
            end
        end
        README:begin
            if(readed)begin
                readed<=0;
                state<=WRITEME;
                rgb<=dmap;
            end else readed<=1;
        end
        WRITEME: begin
            if(readed==2'd3)begin
                readed<=0;
                state <= SWITCH;
            end else readed<=readed+2'd1;
        end
    endcase
end
endmodule

///