// =================================================================
// Module: prn_code_gen
// Description: Channel-level PRN (Gold code) generator that produces
//              the early-late correlator taps needed by the channel:
//                - prompt : on-time chip, bipolar +-1 (2-bit signed)
//                - late   : chip delayed by 0.5 chip, bipolar +-1
//                - dump   : one clk-wide pulse every 1023 chips (1 ms)
//
//              This is NOT the same module as TASK_1's gps_ca_top.v.
//              gps_ca_top advances its G1/G2 registers on every edge
//              of whatever clock it is given (it has no clock-enable),
//              which was fine when it was tested standalone at a
//              dedicated 1.023 MHz clock. In the integrated channel
//              there is only ONE system clock (16.368 MHz), so the
//              G1/G2 registers here are re-implemented with the same
//              polynomials but gated by a chip_en pulse derived from
//              code_tick (2.046 MHz, 2x chip rate), so they advance
//              exactly once per chip (1.023 MHz). prn_selector.v
//              (TASK_1, purely combinational) is reused unchanged.
// =================================================================
module prn_code_gen_up (
    input  wire        clk,         // 16.368 MHz system clock
    input  wire        reset,       // synchronous reset
    input  wire [5:0]  prn_select,  // PRN 1-32 (also passes through SBAS range)
    input  wire        code_tick,   // 2.046 MHz pulse from gps_code_nco (2x chip rate)

    output wire signed [1:0] prompt, // bipolar +1/-1, on-time chip
    output wire signed [1:0] late,   // bipolar +1/-1, delayed by 0.5 chip
    output wire               dump,  // 1 clk-wide pulse once per 1023 chips
    output wire               chip_en, // 1.023 MHz chip-advance pulse (debug visibility)
    output reg                chip_bit // 0/1 chip value, registered/clock-aligned (for verification)
);

    // -----------------------------------------------------------------
    // 1) Divide code_tick (2.046 MHz) by 2 -> chip_en (1.023 MHz).
    //    Two code_ticks = exactly one chip period.
    // -----------------------------------------------------------------
    reg tick_phase;
    always @(posedge clk) begin
        if (reset)
            tick_phase <= 1'b0;
        else if (code_tick)
            tick_phase <= ~tick_phase;
    end
    assign chip_en = code_tick & tick_phase;

    // -----------------------------------------------------------------
    // 2) G1 / G2 Gold-code LFSRs (same polynomials as TASK_1),
    //    advanced once per chip via chip_en.
    //    G1: x^10 + x^3 + 1
    //    G2: x^10 + x^9 + x^8 + x^6 + x^3 + x^2 + 1
    // -----------------------------------------------------------------
    reg [9:0] g1, g2;

    wire g1_fb = g1[9] ^ g1[2];
    wire g2_fb = g2[9] ^ g2[8] ^ g2[7] ^ g2[5] ^ g2[2] ^ g2[1];

    always @(posedge clk) begin
        if (reset) begin
            g1 <= 10'b1111111111;
            g2 <= 10'b1111111111;
        end else if (chip_en) begin
            g1 <= {g1[8:0], g1_fb};
            g2 <= {g2[8:0], g2_fb};
        end
    end

    wire g1_out = g1[9];
    wire g2_selected;

    // Reused as-is from TASK_1 -- purely combinational tap-select mux
    prn_selector PRNSEL (
        .prn_select (prn_select),
        .g2_state   (g2),
        .g2_selected(g2_selected)
    );

    // -----------------------------------------------------------------
    // chip_bit is now REGISTERED (clock-aligned), not a bare combinational
    // wire. It is re-sampled every clk edge, so its transitions line up
    // cleanly with clk/reset for waveform comparison against the
    // standalone golden-reference PRN1 model.
    // -----------------------------------------------------------------
    always @(posedge clk) begin
        if (reset)
            chip_bit <= 1'b0;
        else
            chip_bit <= g1_out ^ g2_selected;  // 0/1 chip value, clock-aligned
    end

    // GPS convention bipolar mapping: chip 0 -> +1, chip 1 -> -1
    wire signed [1:0] prompt_bipolar = chip_bit ? 2'sb11 : 2'sb01;
    assign prompt = prompt_bipolar;

    // -----------------------------------------------------------------
    // 3) "late" = prompt delayed by exactly one code_tick period.
    //    One code_tick period = 0.5 chip (code_tick runs at 2x chip rate),
    //    which is exactly the early-late spacing the diagram calls for.
    // -----------------------------------------------------------------
    reg signed [1:0] late_reg;
    always @(posedge clk) begin
        if (reset)
            late_reg <= 2'sb01;
        else if (code_tick)
            late_reg <= prompt_bipolar;
    end
    assign late = late_reg;

    // -----------------------------------------------------------------
    // 4) dump: one clk-wide pulse every 1023 chips (=1 ms), marking
    //    "this C/A code epoch just completed".
    // -----------------------------------------------------------------
    reg [9:0] chip_count;
    reg       dump_reg;
    always @(posedge clk) begin
        if (reset) begin
            chip_count <= 10'd0;
            dump_reg   <= 1'b0;
        end else begin
            dump_reg <= 1'b0;
            if (chip_en) begin
                if (chip_count == 10'd1022) begin
                    chip_count <= 10'd0;
                    dump_reg   <= 1'b1;
                end else begin
                    chip_count <= chip_count + 10'd1;
                end
            end
        end
    end
    assign dump = dump_reg;

endmodule
