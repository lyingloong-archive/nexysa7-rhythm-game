// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  PS2Receiver - PS/2 frame decoder
//
//  Samples the 11-bit PS/2 frames and keeps the last four scan codes.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------
//
// PS/2 frame (11 bits, LSB first):
//   bit 0     start bit, always 0
//   bits 1-8  data byte, LSB first
//   bit 9     odd parity (ignored here)
//   bit 10    stop bit, always 1
//
// A key press sends one scan code. An extended key sends 0xE0 first; a release
// sends 0xF0 followed by the scan code. The receiver keeps the last four bytes
// so the key decoder can inspect the whole sequence.
module PS2Receiver(
    input             clk,
    input             kclk,        // PS/2 clock
    input             kdata,       // PS/2 data
    output     [31:0] keycodeout,  // last four scan codes, newest in [7:0]
    output     [0:0]  flagout      // toggles on every key press
);

    wire kclkf, kdataf;

    reg  [7:0]  datacur;
    reg  [3:0]  cnt;
    reg  [31:0] keycode;
    reg         save;
    reg         flag2;
    reg         can;               // next byte is the released key

    initial begin
        datacur = 8'h00;
        cnt     = 4'd0;
        keycode = 32'h00000000;
        save    = 1'b0;
        flag2   = 1'b0;
        can     = 1'b0;
    end

    debouncer debounce(
        .clk (clk),
        .I0  (kclk),
        .I1  (kdata),
        .O0  (kclkf),
        .O1  (kdataf)
    );

    // cnt = 0      : start bit
    // cnt = 1..8   : data bits
    // cnt = 9      : parity bit (ignored), byte complete
    // cnt = 10     : stop bit
    always @(posedge clk) begin
        if (kclkf) begin
            save <= 1'b1;
        end else if (save) begin
            save <= 1'b0;
            case (cnt)
                4'd0: ;                                  // start bit
                4'd1: datacur[0] <= kdataf;
                4'd2: datacur[1] <= kdataf;
                4'd3: datacur[2] <= kdataf;
                4'd4: datacur[3] <= kdataf;
                4'd5: datacur[4] <= kdataf;
                4'd6: datacur[5] <= kdataf;
                4'd7: datacur[6] <= kdataf;
                4'd8: datacur[7] <= kdataf;
                4'd9: begin
                    keycode[31:24] <= keycode[23:16];
                    keycode[23:16] <= keycode[15:8];
                    keycode[15:8]  <= keycode[7:0];
                    keycode[7:0]   <= datacur;
                    if (datacur == 8'hf0) begin
                        can <= 1'b1;                     // break code prefix
                    end else if (can) begin
                        can <= 1'b0;                     // key release, ignore
                    end else begin
                        flag2 <= ~flag2;                 // real key press
                    end
                end
                4'd10: ;                                 // stop bit
            endcase
            if (cnt <= 4'd9) cnt <= cnt + 4'd1;
            else             cnt <= 4'd0;
        end
    end

    assign flagout    = flag2;
    assign keycodeout = keycode;

endmodule
