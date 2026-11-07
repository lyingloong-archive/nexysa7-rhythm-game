// -----------------------------------------------------------------------------
//  Main - top level of the rhythm game
//
//  Instantiates the keyboard/button front end, the note scheduler and renderer,
//  the VGA output unit, the music player and the 7-segment display driver.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------
module Main(
    input               clk,        // 100 MHz board clock
    input      [15:0]   sw,         // switches, see docs/hardware.md
    input               nrst,       // CPU_RESETN, active low
    input               btn2,       // BTNC, active high
    input               PS2_CLK,    // PS/2 keyboard clock
    input               PS2_DATA,   // PS/2 keyboard data
    output     [15:0]   led,        // status LEDs (state, flags, debug byte)
    output     [11:0]   rgb,        // VGA colour, 4 bits per channel
    output              pwm,        // audio PWM output
    output              sd,         // audio amplifier enable
    output              VGA_HS,
    output              VGA_VS,
    output     [7:0]    ledsel,     // 7-segment anodes
    output     [7:0]    leddata     // 7-segment cathodes
);

    wire rst = ~nrst;

    // -------------------------------------------------------------------------
    // Game state
    // -------------------------------------------------------------------------
    localparam START = 2'd0;   // title screen
    localparam WAIT  = 2'd1;   // chart loaded, waiting for the start press
    localparam RUN   = 2'd2;   // playing
    localparam STOP  = 2'd3;   // result / error screen
    reg [3:0] state;           // 4 bits because the state is also shown on the LEDs

    // -------------------------------------------------------------------------
    // Inputs and user switches
    // -------------------------------------------------------------------------
    wire        clear;         // one-shot confirm / hit event
    wire        wauto;         // auto-play toggle from the keyboard ("1")
    wire        wstrong;       // invincible toggle from the keyboard ("2")
    wire [1:0]  wspeed;        // keyboard speed nudge ("4"/"5"/"6")
    wire        wchange;       // "9": cycle the picture style

    reg  [15:0] sww;           // switches, registered for one cycle
    always @(posedge clk) sww <= sw;

    wire auto = sww[6] | wauto;
    wire keep = sww[0] | wstrong;

    // -------------------------------------------------------------------------
    // Note scheduling, judging and rendering
    // -------------------------------------------------------------------------
    wire [15:0] nowpos;        // position inside the current track segment
    wire [15:0] readlen;       // length of the note currently being timed
    wire        WA;            // wrong note
    wire        okpre;         // chart is loaded and the game may start
    wire        solvenote;     // a note was hit
    wire        endpass;       // end of the song
    wire [15:0] notex, notey;  // screen position of the current note
    wire [11:0] colorp;        // HUD colour
    wire [17:0] BLOn;          // background page offset
    wire [31:0] score;
    wire        nnote0;        // note colour select
    wire signed [15:0] wmodi;  // judged timing offset, used by the renderer
    wire [31:0] send;          // 7-segment payload
    wire [15:0] nouu;          // HUD payload for the LEDs
    wire [15:0] perc;          // current position in the song, in percent
    wire [7:0]  speednote;     // note speed shown on the HUD
    wire        fresh;         // redraw request
    wire [31:0] cpp;           // clocks per percent of the track
    wire [31:0] putgo;         // stop-screen timer

    // -------------------------------------------------------------------------
    // Video and audio
    // -------------------------------------------------------------------------
    wire [14:0] vmadd;         // framebuffer write address
    wire [11:0] vrgb;          // framebuffer write data
    wire        vwe;           // framebuffer write enable
    reg  [1:0]  style;         // picture style selected with "9"

    reg startmusic, endmusic, wrongmusic;

    // -------------------------------------------------------------------------
    // Timer unused high halves (kept so the 32-bit timer ports stay connected)
    // -------------------------------------------------------------------------
    wire [15:0] unused_pos_timer;
    wire [15:0] unused_read_timer;

    // -------------------------------------------------------------------------
    // One-cycle delayed fake click (used by auto-play)
    // -------------------------------------------------------------------------
    reg  fakeclick;
    wire wfakeclick;
    always @(posedge clk) fakeclick <= wfakeclick;

    // -------------------------------------------------------------------------
    // Power-on state
    // -------------------------------------------------------------------------
    reg  [15:0] saveperc;      // HUD position frozen on the error screen
    reg         wa;            // "wrong note" flag used by the renderer
    reg         had;           // set after the first confirm press
    reg         instart, inprepare, tohalt;

    initial begin
        state      = START;
        instart    = 1'b0;
        inprepare  = 1'b0;
        tohalt     = 1'b0;
        had        = 1'b0;
        sww        = 16'd0;
        style      = 2'd0;
        wa         = 1'b0;
        saveperc   = 16'd0;
        startmusic = 1'b0;
        endmusic   = 1'b0;
        wrongmusic = 1'b0;
        fakeclick  = 1'b0;
    end

    // -------------------------------------------------------------------------
    // Keyboard / button front end
    // -------------------------------------------------------------------------
    getclicked gettap(
        .clk       (clk),
        .PS2_CLK   (PS2_CLK),
        .PS2_DATA  (PS2_DATA),
        .btn       (btn2),
        .auto      (auto && state == RUN),
        .clear     (clear),
        .wspeed    (wspeed),
        .wchange   (wchange),
        .wauto     (wauto),
        .wstrong   (wstrong)
    );

    // -------------------------------------------------------------------------
    // Note scheduler
    // -------------------------------------------------------------------------
    Solve #(.X(16'd200), .Y(16'd150)) solver(
        .clk       (clk),
        .halt      (tohalt),
        .prepare   (inprepare),
        .start     (instart),
        .next      ((clear || fakeclick) && (state == RUN)),
        .keep      (keep),
        .switcher  (sww[7]),
        .sw2       (sww[8]),
        .auto      (auto),
        .length    (readlen),
        .now       (nowpos),
        .debug     (sww[14:10]),
        .dataput   (nouu),
        .dataput2  (send),
        .wrong     (WA),
        .solved    (solvenote),
        .fakeclick (wfakeclick),
        .ready     (okpre),
        .score     (score),
        .wfresh    (fresh),
        .wnotex    (notex),
        .wnotey    (notey),
        .nnote0    (nnote0),
        .wBLOn     (BLOn),
        .wcolorp   (colorp),
        .wperc     (perc),
        .wwmodi    (wmodi),
        .endpass   (endpass)
    );

    // -------------------------------------------------------------------------
    // Frame composer
    // -------------------------------------------------------------------------
    Fresh #(.X(16'd200), .Y(16'd150)) fresher(
        .clk       (clk),
        .fresh     (fresh || (state == START) || instart),
        .perc      (wa ? saveperc : perc),
        .notex     (notex),
        .notey     (notey),
        .score     (score),
        .speed     (speednote),
        .notecolor (nnote0),
        .BLOn      (BLOn),
        .colorp    (colorp),
        .madd      (vmadd),
        .vwe       (vwe),
        .wastate   ((putgo < 32'd2) && (state == STOP)),
        .auto      (auto),
        .keep      (keep),
        .wmodi     (wmodi),
        .prgb      (vrgb)
    );

    // -------------------------------------------------------------------------
    // Picture style (only changes the colour blending in the output stage)
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (wchange) style <= style + 2'd1;
    end

    // -------------------------------------------------------------------------
    // VGA output
    // -------------------------------------------------------------------------
    DU show(
        .mode      (style),
        .rst       (rst),
        .clk       (clk),
        .inrgb     (vrgb),
        .we        (vwe && (state >= 1)),
        .addr      (vmadd),
        .rgb       (rgb),
        .VGA_HS    (VGA_HS),
        .VGA_VS    (VGA_VS)
    );

    // -------------------------------------------------------------------------
    // Timers and note speed
    // -------------------------------------------------------------------------
    CounterW #(.MAX(32'd360)) position_timer(
        .WIDTH (cpp),
        .clk   (clk),
        .rst   (state < RUN),
        .out   ({unused_pos_timer, nowpos})
    );

    CounterW #(.MAX(32'd1000000)) length_timer(
        .WIDTH (cpp),
        .clk   (clk),
        .rst   ((state < RUN) || solvenote),
        .out   ({unused_read_timer, readlen})
    );

    speeder speed_ctl(
        .clk       (clk),
        .cpp       (cpp),
        .wspeed    (wspeed),
        .con       (sww[5:3]),
        .speednote (speednote)
    );

    // Stop-screen timer: 1 s per tick, never used beyond the first two ticks.
    Counter #(.WIDTH(32'd100000000), .MAX(32'd100000)) stop_timer(
        .clk (clk),
        .rst (state != STOP),
        .out (putgo)
    );

    // -------------------------------------------------------------------------
    // Music player
    // -------------------------------------------------------------------------
    Music music(
        .WIDTH      (cpp),
        .clk        (clk),
        .startmusic (startmusic),
        .rst        (rst),
        .endmusic   (endmusic),
        .wrongmusic (wrongmusic),
        .pwm        (pwm),
        .sd         (sd)
    );

    // -------------------------------------------------------------------------
    // 7-segment display
    // -------------------------------------------------------------------------
    transseg seg(
        .clk          (clk),
        .rst          (1'd0),
        .output_data  (send),
        .output_valid (8'hff),
        .seg_data     (leddata),
        .seg_an       (ledsel)
    );

    // -------------------------------------------------------------------------
    // Status LEDs
    //
    //  bit 15..8 : colour/debug byte (SW15 selects the colour mixer output)
    //  bit  7..4 : SW14..SW11, debug selector
    //  bit  3    : auto-play
    //  bit  2    : invincible
    //  bit  1..0 : state[1:0]
    //
    // NOTE: the concatenation below is 18 bits wide; the original design lets
    // the two MSBs of `lled` be dropped by the 16-bit assignment. Kept as-is to
    // preserve the existing LED behaviour.
    // -------------------------------------------------------------------------
    wire [15:0] mix  = {colorp, notex[3:0]};
    wire [15:0] lled = sww[15] ? mix : nouu;

    assign led[15:0] = {lled[15:8], sww[14:11], auto, keep, state};

    // -------------------------------------------------------------------------
    // Main state machine
    //
    //  START -> WAIT -> RUN -> STOP -> START
    //    - START: draw the title screen; the first confirm press loads the chart
    //    - WAIT : wait for okpre, then the second press starts the song
    //    - RUN  : play until endpass / wrong note / SW2 (restart)
    //    - STOP : show the result, then return to START after the timer
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        case (state)
            START: begin
                wa           <= 1'b0;
                wrongmusic    = 1'b0;
                endmusic     <= 1'b1;
                if (clear || had) begin
                    inprepare <= 1'b1;
                    instart   <= 1'b0;
                    tohalt    <= 1'b0;
                    state     <= WAIT;
                    had       <= 1'b1;
                end
            end

            WAIT: begin
                endmusic <= 1'b0;
                if (okpre && clear) begin
                    instart    <= 1'b1;
                    inprepare  <= 1'b0;
                    startmusic <= 1'b1;
                    state      <= RUN;
                end
            end

            RUN: begin
                instart    <= 1'b0;
                startmusic <= 1'b0;
                if (endpass) begin
                    tohalt <= 1'b1;
                    state  <= STOP;
                end else if (sww[2]) begin
                    state     <= START;
                    tohalt    <= 1'b1;
                    endmusic  <= 1'b1;
                end else if (WA) begin
                    tohalt     <= 1'b1;
                    wa         <= 1'b1;
                    wrongmusic <= 1'b1;
                    saveperc   <= perc;
                    state      <= STOP;
                    endmusic   <= 1'b1;
                end
            end

            STOP: begin
                if ((putgo >= 32'd2) && clear) begin
                    state <= START;
                end
            end

            default:;
        endcase
    end

endmodule
