// =================================================================
// Module: top_system
// Description: THE FINAL TOP MODULE. Per supervisor's architecture:
//                1) gps_channel  -- receiver correlator core
//                2) if_stimulus_gen -- separate IF module (PRN 1,
//                   zero Doppler on both carrier and code)
//              These two are SIBLINGS, wired together only here --
//              if_stimulus_gen is never instantiated inside
//              gps_channel, and vice versa.
//
//              if_stimulus_gen outputs L1 in SIGN-MAGNITUDE format
//              (per supervisor: if_sign + if_mag concatenated).
//              gps_channel's internal mult3x3 stage expects its
//              if_sample input as standard two's-complement, so an
//              sm2tc converter sits on the wire between them.
//
//              carrier_nco / code_nco are exposed as top-level inputs
//              (Doppler control words) -- tie them to the nominal
//              zero-Doppler values in simulation:
//                carrier_nco = 32'h4000_0000  (4.092 MHz)
//                code_nco    = 32'h2000_0000  (2.046 MHz)
// =================================================================
module top_system (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] carrier_nco,
    input  wire [31:0] code_nco,
    input  wire [5:0]  prn_no,

    // ---- IF module's own raw sign-magnitude outputs (visibility) ----
    output wire         if_sign,
    output wire [1:0]   if_mag,
    output wire [2:0]   L1,

    // ---- gps_channel intermediate stage outputs (visibility) ----
    output wire signed [2:0]  ILO,
    output wire signed [2:0]  QLO,
    output wire signed [2:0]  if_monitor,
    output wire signed [1:0]  prompt,
    output wire signed [1:0]  late,
    output wire               dump,
    output wire               dump_out,
    output wire               code_tick,
    output wire               chip_en,
    output wire               chip_bit,

    // ---- final correlator outputs ----
    output wire signed [15:0] I_prompt,
    output wire signed [15:0] I_late,
    output wire signed [15:0] Q_prompt,
    output wire signed [15:0] Q_late
);

    // =================================================================
    // Block 1: IF module (sibling, NOT inside gps_channel)
    // Hardwired PRN 1, zero Doppler on carrier and code both -- these
    // are now fixed inside if_stimulus_gen itself (localparam, not
    // ports), so no parameter overrides here anymore.
    // =================================================================
    if_stimulus_gen IF_MODULE (
        .clk    (clk),
        .reset  (reset),
        .if_sign(if_sign),
        .if_mag (if_mag),
        .L1     (L1)
    );

    // =================================================================
    // Bridge: L1 (sign-magnitude) -> if_sample (two's-complement)
    // =================================================================
    wire signed [2:0] if_sample_tc;
    sm2tc #(.WIDTH(3)) SM2TC_IF (.sm(L1), .tc(if_sample_tc));

    // =================================================================
    // Block 2: gps_channel (sibling, receives if_sample from Block 1)
    // =================================================================
    gps_channel CHANNEL (
        .clk        (clk),
        .reset      (reset),
        .carrier_nco(carrier_nco),
        .code_nco   (code_nco),
        .prn_no     (prn_no),
        .if_sample  (if_sample_tc),

        .ILO        (ILO),
        .QLO        (QLO),
        .if_monitor (if_monitor),
        .prompt     (prompt),
        .late       (late),
        .dump       (dump),
        .dump_out   (dump_out),
        .code_tick  (code_tick),
        .chip_en    (chip_en),
        .chip_bit   (chip_bit),

        .I_prompt   (I_prompt),
        .I_late     (I_late),
        .Q_prompt   (Q_prompt),
        .Q_late     (Q_late)
    );

endmodule
