// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  transseg - nibble to 7-segment decoder
//
//  Decodes the current nibble into the active-low segment pattern.
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------
module transseg(
    input             clk,
    input             rst,
    input      [31:0] output_data,
    input      [7:0]  output_valid,

    output reg [7:0]  seg_data,
    output     [7:0]  seg_an
);

    wire [3:0] mid;

    Segment seg(
        .clk          (clk),
        .rst          (rst),
        .output_data  (output_data),
        .output_valid (output_valid),
        .seg_data     (mid),
        .seg_an       (seg_an)
    );

    // Active-low segment patterns: {dp, g, f, e, d, c, b, a}.
    localparam zero  = 8'b0000_0011,
               one   = 8'b1001_1111,
               two   = 8'b0010_0101,
               three = 8'b0000_1101,
               four  = 8'b1001_1001,
               five  = 8'b0100_1001,
               six   = 8'b0100_0001,
               seven = 8'b0001_1111,
               eight = 8'b0000_0001,
               nine  = 8'b0000_1001,
               ten   = 8'b0001_0001,
               B     = 8'b1100_0001,
               C     = 8'b0110_0011,
               D     = 8'b1000_0101,
               E     = 8'b0110_0001,
               F     = 8'b0111_0001;

    always @(*) begin
        case (mid)
            4'd0:  seg_data = zero;
            4'd1:  seg_data = one;
            4'd2:  seg_data = two;
            4'd3:  seg_data = three;
            4'd4:  seg_data = four;
            4'd5:  seg_data = five;
            4'd6:  seg_data = six;
            4'd7:  seg_data = seven;
            4'd8:  seg_data = eight;
            4'd9:  seg_data = nine;
            4'd10: seg_data = ten;
            4'd11: seg_data = B;
            4'd12: seg_data = C;
            4'd13: seg_data = D;
            4'd14: seg_data = E;
            4'd15: seg_data = F;
            default: seg_data = 8'b1111_1111;
        endcase
    end

endmodule
