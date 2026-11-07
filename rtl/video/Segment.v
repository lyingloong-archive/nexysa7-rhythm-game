// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  Segment - 8-digit 7-segment scanner
//
//  Multiplexes the 8 digits, selects the active anode and outputs the current
//  nibble. One digit is visible for 250,000 clock cycles (2.5 ms at 100 MHz).
//
//  Project : nexysa7-rhythm-game (USTC 2024 Fall, Digital Circuits Lab #8)
//  License : MIT (see LICENSE)
// -----------------------------------------------------------------------------
module Segment(
    input             clk,
    input             rst,
    input      [31:0] output_data,
    input      [7:0]  output_valid,

    output reg [3:0]  seg_data,   // nibble of the current digit
    output     [7:0]  seg_an      // active-low digit select
);

    reg [31:0] counter;

    always @(posedge clk) begin
        if (rst)
            counter <= 32'd0;
        else if (counter >= 32'd249999)
            counter <= 32'd0;
        else
            counter <= counter + 32'd1;
    end

    reg [2:0] seg_pid;   // current digit, 0..7
    reg [7:0] seg_id;    // selected digit, 0 when the digit is blanked

    initial begin
        counter = 32'd0;
        seg_pid = 3'd0;
        seg_id  = 8'd0;
    end

    always @(posedge clk) begin
        if (counter >= 32'd249999) begin
            if (seg_pid == 3'd7) seg_pid <= 3'd0;
            else                 seg_pid <= seg_pid + 3'd1;
        end
    end

    always @(posedge clk) begin
        seg_id <= output_valid[seg_pid] ? seg_pid : 8'd0;
    end

    assign seg_an = ~(8'd1 << seg_id);

    always @(*) begin
        seg_data = 4'd0;
        case (seg_id)
            8'd0: seg_data = output_data[3:0];
            8'd1: seg_data = output_data[7:4];
            8'd2: seg_data = output_data[11:8];
            8'd3: seg_data = output_data[15:12];
            8'd4: seg_data = output_data[19:16];
            8'd5: seg_data = output_data[23:20];
            8'd6: seg_data = output_data[27:24];
            8'd7: seg_data = output_data[31:28];
        endcase
    end

endmodule
