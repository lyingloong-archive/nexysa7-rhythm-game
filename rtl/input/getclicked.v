// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  getclicked - keyboard and button front end
//
//  Decodes PS/2 scan codes, produces one-shot key events and implements the
//  auto / invincible / speed / style toggles.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------
//
// Keyboard keys (PS/2 scan code set 2):
//   1  -> toggle auto-play
//   2  -> toggle invincible mode
//   4  -> faster, 5 -> slower, 6 -> default speed
//   9  -> next picture style
//   any other key -> a hit / confirm event
module getclicked(
    input             clk,
    input             PS2_CLK,
    input             PS2_DATA,
    input             btn,        // BTNC, used as an extra confirm/hit button
    input             auto,       // auto-play is on, so hits are generated internally
    output            wauto,
    output            wstrong,
    output     [1:0]  wspeed,
    output            wchange,
    output     [31:0] debuger,    // last scan code, useful on a logic analyser
    output            clear       // one-shot hit / confirm event
);

    wire [31:0] keycode32;
    wire [7:0]  data = keycode32[7:0];
    wire        dee;          // toggles on every key press

    keyboard_top key(
        .CLK100MHZ (clk),
        .PS2_CLK   (PS2_CLK),
        .PS2_DATA  (PS2_DATA),
        .keycode   (keycode32),
        .dee       (dee)
    );

    localparam KEY1 = 8'h16;
    localparam KEY2 = 8'h1e;
    localparam KEY4 = 8'h25;
    localparam KEY5 = 8'h2e;
    localparam KEY6 = 8'h36;
    localparam KEY9 = 8'h46;

    reg        save;      // previous value of the key strobe
    reg        tap;       // one-cycle "any other key" event
    reg        autor;
    reg        strongr;
    reg  [1:0] speed;
    reg        change;
    reg        clearr;
    reg        btn_prev;

    initial begin
        save     = 1'b0;
        tap      = 1'b0;
        autor    = 1'b0;
        strongr  = 1'b0;
        speed    = 2'd0;
        change   = 1'b0;
        clearr   = 1'b0;
        btn_prev = 1'b0;
    end

    assign wspeed  = speed;
    assign wauto   = autor;
    assign wstrong = strongr;
    assign wchange = change;
    assign debuger = keycode32;

    // The PS/2 receiver toggles `dee` for every key press. Act on either edge of
    // that toggle so one physical press produces exactly one action, and clear
    // the one-cycle events when no edge is present.
    always @(posedge clk) begin
        if (dee != save) begin
            save <= dee;
            case (data)
                KEY1: autor    <= ~autor;
                KEY2: strongr  <= ~strongr;
                KEY4: speed    <= 2'd1;
                KEY5: speed    <= 2'd2;
                KEY6: speed    <= 2'd3;
                KEY9: change   <= 1'b1;
                default: tap   <= 1'b1;
            endcase
        end else begin
            speed  <= 2'd0;
            change <= 1'b0;
            tap    <= 1'b0;
        end
    end

    // BTNC edge detector: one-cycle `clearr` pulse per press.
    always @(posedge clk) begin
        if (btn) begin
            if (btn_prev) begin
                clearr <= 1'b0;
            end else begin
                btn_prev <= 1'b1;
                clearr   <= 1'b1;
            end
        end else begin
            btn_prev <= 1'b0;
        end
    end

    // Auto-play suppresses external hits so the demo cannot be interrupted.
    assign clear = (tap | clearr) & (~auto);

endmodule
