// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  audio - tone generator
//
//  Converts a note number into a period and a PWM waveform, including the note
//  decoder table and the volume envelope.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------
// Sound output stage: turns a period from the decoder into a PWM waveform and
// slowly sweeps the duty cycle to produce a simple envelope.
module sound (
    input      [11:0] period,   // period of the note, in clock cycles
    input             clk,
    output            pwm
);
    // Reference frequencies at 100 MHz (A4 = 440 Hz):
    //   do 261.6 Hz -> 382263 clk    sol 392.0 Hz -> 255102 clk
    //   re 293.6 Hz -> 340599 clk    la  440.0 Hz -> 227272 clk
    //   mi 329.6 Hz -> 303398 clk    si  493.8 Hz -> 202511 clk
    //   fa 349.2 Hz -> 286369 clk
    reg [11:0] h_time = 12'd1;
    wire       pulse;

    pwm_gen pg1 (
        .period (period),
        .h_time (h_time),
        .clk    (clk),
        .wave   (pwm),
        .pulse  (pulse)
    );

    reg up = 1'b1;
    always @(posedge clk) begin
        if (pulse) begin
            if (up) begin
                h_time <= h_time + 12'd1;
                if (h_time > period) up <= 1'b0;
            end else begin
                h_time <= h_time - 12'd1;
                if (h_time == 12'd1) up <= 1'b1;
            end
        end
    end
endmodule

// Maps a 5-bit note number to the period used by `sound`.
//   bit 4..3 : octave selector (see the table below)
//   bit 2..0 : note (0 = rest, 1..7 = do..si)
module Music_decoder (
    input      [4:0]  cin,
    output reg [11:0] cout,
    output reg        sd        // 1 = sound enabled, 0 = rest
);
    always @(*) begin
        sd = 1'b1;
        case (cin)
            5'b00000: begin sd = 1'b0; cout = 12'd618; end   // rest
            5'b00001: cout = 12'd618;   // low 1
            5'b00010: cout = 12'd583;   // low 2
            5'b00011: cout = 12'd550;   // low 3
            5'b00100: cout = 12'd535;   // low 4
            5'b00101: cout = 12'd505;   // low 5
            5'b00110: cout = 12'd476;   // low 6
            5'b00111: cout = 12'd450;   // low 7
            5'b01000: cout = 12'd437;   // mid 1
            5'b01001: cout = 12'd412;   // mid 2
            5'b01010: cout = 12'd389;   // mid 3
            5'b01011: cout = 12'd378;   // mid 4
            5'b01100: cout = 12'd357;   // mid 5
            5'b01101: cout = 12'd337;   // mid 6
            5'b01110: cout = 12'd327;   // mid 7
            5'b01111: cout = 12'd309;   // high 1
            5'b10000: cout = 12'd291;   // high 2
            5'b10001: cout = 12'd275;   // high 3
            5'b10010: cout = 12'd267;   // high 4
            5'b10011: cout = 12'd252;   // high 5
            5'b10100: cout = 12'd238;   // high 6
            5'b10101: cout = 12'd231;   // high 7
            5'b10110: cout = 12'd425;   // special 1
            5'b10111: cout = 12'd277;   // special 2
            5'b11000: cout = 12'd218;   // highest 1
            5'b11001: cout = 12'd206;
            5'b11010: cout = 12'd195;
            5'b11011: cout = 12'd189;
            5'b11100: cout = 12'd178;
            5'b11101: cout = 12'd168;
            5'b11110: cout = 12'd159;
            default:  cout = 12'd618;   // low 1
        endcase
    end
endmodule

// Top of the audio path: decodes the note, selects the period and enables the
// PWM output. `note_en` is a one-cycle strobe for the next note.
module audio (
    input             clk,
    input             rstn,        // active-low reset (kept for compatibility)
    input             note_en,
    input      [3:0]  note,        // bit 3 = octave, bits 2..0 = note
    output            pwm,
    output            sd
);
    reg  [4:0] douta2;
    wire [4:0] douta;
    reg        higher;

    initial begin
        higher = 1'b0;
        douta2 = 5'd0;
    end

    // High octave is the low-octave table entry plus seven.
    assign douta = douta2 + (higher ? 5'd7 : 5'd0);

    wire [11:0] period;
    wire        sd1;

    always @(posedge note_en) begin
        higher <= note[3];
        case (note[2:0])
            3'b000: douta2 <= 5'b00000;
            3'b001: douta2 <= 5'b01000;
            3'b010: douta2 <= 5'b01001;
            3'b011: douta2 <= 5'b01010;
            3'b100: douta2 <= 5'b01011;
            3'b101: douta2 <= 5'b01100;
            3'b110: douta2 <= 5'b01101;
            3'b111: douta2 <= 5'b01110;
        endcase
    end

    Music_decoder md (
        .cin  (douta),
        .cout (period),
        .sd   (sd1)
    );

    wire pwm1;

    sound music1 (
        .period (period),
        .clk    (clk),
        .pwm    (pwm1)
    );

    assign sd  = sd1;
    assign pwm = sd1 & pwm1;

endmodule
