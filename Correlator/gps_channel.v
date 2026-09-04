// =================================================================
// Module: gps_channel
// Description: The GPS L1 C/A correlator channel. Per supervisor's
//              updated architecture:
//                - carrier_nco and code_nco are now RUNTIME-TUNABLE
//                  frequency control words (Doppler control), not
//                  fixed parameters. They drive the internal carrier
//                  NCO (Task 2) and code NCO (Task 3) phase
//                  accumulators every clock cycle.
//                - if_sample comes from an EXTERNAL, separate IF
//                  module (NOT instantiated inside this channel -
//                  it is a sibling block, wired in at the top level).
//                - Every intermediate stage signal (ILO/QLO,
//                  if_monitor, prompt/late/dump, code_tick/chip_en)
//                  is exposed at this module's own boundary, so it
//                  can be probed directly with Mark Debug / ILA
//                  without reaching into nested sub-instances.
//
//              Nominal (zero-Doppler) values to drive from outside:
//                carrier_nco = 32'h4000_0000  (-> 4.092 MHz carrier)
//                code_nco    = 32'h2000_0000  (-> 2.046 MHz code_tick)
// =================================================================
module gps_channel (
    input  wire               clk,         // 16.368 MHz system clock
    input  wire               reset,       // synchronous reset, shared by all sub-blocks
    input  wire [31:0]        carrier_nco, // carrier NCO frequency control word (Doppler)
    input  wire [31:0]        code_nco,    // code NCO frequency control word (Doppler)
    input  wire [5:0]         prn_no,      // PRN 1-32
    input  wire signed [2:0]  if_sample,   // 3-bit signed IF sample, from the separate IF module

    // ---- intermediate stage outputs (debug visibility) ----
    output wire signed [2:0]  ILO,
    output wire signed [2:0]  QLO,
    output wire signed [2:0]  if_monitor,   // passthrough of if_sample, for convenient debug grouping
    output wire signed [1:0]  prompt,
    output wire signed [1:0]  late,
    output wire               dump,
    output wire               dump_out,     // *** ADDED beyond miss's list: dump delayed 2 clk
                                             // to align with the moment ACCUMDATA actually
                                             // latches - use this one for ILA trigger / TB sync
    output wire               code_tick,    // raw 2.046 MHz code NCO tick
    output wire               chip_en,      // divided 1.023 MHz chip-advance pulse
    output wire               chip_bit,     // registered/clock-aligned 0/1 chip value

    // ---- final correlator outputs ----
    output wire signed [15:0] I_prompt,
    output wire signed [15:0] I_late,
    output wire signed [15:0] Q_prompt,
    output wire signed [15:0] Q_late
);

    assign if_monitor = if_sample;

    // =================================================================
    // Stage 1: Carrier NCO (TASK_2) -> ILO / QLO
    // carrier_nco is now a runtime input (Doppler control), not a fixed
    // parameter.
    // =================================================================
    nco_top #(
        .ACC_WIDTH(32), .LUT_ADDR_WIDTH(6), .OUT_WIDTH(3)
    ) carrier_nco_inst (
        .clk       (clk),
        .reset     (reset),
        .phase_step(carrier_nco),
        .I_out     (ILO),
        .Q_out     (QLO)
    );

    // =================================================================
    // Stage 2: Code NCO (TASK_3) -> code_tick
    // code_nco is now a runtime input (Doppler control).
    // =================================================================
    gps_code_nco #(
        .PHASE_WIDTH(32)
    ) code_nco_inst (
        .clk       (clk),
        .rst       (reset),
        .phase_step(code_nco),
        .code_tick (code_tick)
    );

    // =================================================================
    // Stage 3: PRN code generator -> prompt / late / dump / chip_en
    // =================================================================
    prn_code_gen_up prn_gen_inst (
        .clk       (clk),
        .reset     (reset),
        .prn_select(prn_no),
        .code_tick (code_tick),
        .prompt    (prompt),
        .late      (late),
        .dump      (dump),
        .chip_en   (chip_en),
        .chip_bit  (chip_bit)
    );

    // =================================================================
    // Stage 4: Carrier wipe-off  if_sample x ILO -> Io ,  if_sample x QLO -> Qo
    // (mult3x3, TASK_MULTI) -- registered, sign-magnitude output
    // =================================================================
    wire [3:0] Io_sm, Qo_sm;

    mult3x3 MIX_I (.clk(clk), .reset(reset), .a(if_sample), .b(ILO), .p(Io_sm));
    mult3x3 MIX_Q (.clk(clk), .reset(reset), .a(if_sample), .b(QLO), .p(Qo_sm));

    wire signed [3:0] Io, Qo;
    sm2tc #(.WIDTH(4)) SM2TC_IO (.sm(Io_sm), .tc(Io));
    sm2tc #(.WIDTH(4)) SM2TC_QO (.sm(Qo_sm), .tc(Qo));

    // -----------------------------------------------------------------
    // mult3x3 registers its output (1 clk latency). prompt/late are
    // combinational off the chip register (0 latency), so delay them by
    // 1 cycle here so they meet the now-1-cycle-delayed Io/Qo in step,
    // at the next (also registered) multiply stage.
    // -----------------------------------------------------------------
    reg signed [1:0] prompt_d1, late_d1;
    always @(posedge clk) begin
        if (reset) begin
            prompt_d1 <= 2'sb01;
            late_d1   <= 2'sb01;
        end else begin
            prompt_d1 <= prompt;
            late_d1   <= late;
        end
    end

    // =================================================================
    // Stage 5: Despreading
    //   Io x prompt -> I_prompt path   Io x late -> I_late path
    //   Qo x prompt -> Q_prompt path   Qo x late -> Q_late path
    // (mult4x2, TASK_MULTI) -- registered, sign-magnitude output
    // =================================================================
    wire [3:0] Ip_sm, Il_sm, Qp_sm, Ql_sm;

    mult4x2 M_I_P (.clk(clk), .reset(reset), .a(Io), .b(prompt_d1), .p(Ip_sm));
    mult4x2 M_I_L (.clk(clk), .reset(reset), .a(Io), .b(late_d1),   .p(Il_sm));
    mult4x2 M_Q_P (.clk(clk), .reset(reset), .a(Qo), .b(prompt_d1), .p(Qp_sm));
    mult4x2 M_Q_L (.clk(clk), .reset(reset), .a(Qo), .b(late_d1),   .p(Ql_sm));

    wire signed [3:0] Ip, Il, Qp, Ql;
    sm2tc #(.WIDTH(4)) SM2TC_IP (.sm(Ip_sm), .tc(Ip));
    sm2tc #(.WIDTH(4)) SM2TC_IL (.sm(Il_sm), .tc(Il));
    sm2tc #(.WIDTH(4)) SM2TC_QP (.sm(Qp_sm), .tc(Qp));
    sm2tc #(.WIDTH(4)) SM2TC_QL (.sm(Ql_sm), .tc(Ql));

    // -----------------------------------------------------------------
    // dump must reach the accumulators aligned with Ip/Il/Qp/Ql, which
    // are now 2 clk cycles behind the chip boundary that produced them
    // (1 cycle through mult3x3, 1 more through mult4x2).
    // -----------------------------------------------------------------
    reg dump_d1, dump_d2;
    always @(posedge clk) begin
        if (reset) begin
            dump_d1 <= 1'b0;
            dump_d2 <= 1'b0;
        end else begin
            dump_d1 <= dump;
            dump_d2 <= dump_d1;
        end
    end
    wire dump_aligned = dump_d2;
    assign dump_out = dump_aligned;

    // =================================================================
    // Stage 6: 1ms coherent accumulators (TASK_ACCUMULATOR)
    // =================================================================
    accumulator_1ms ACC_I_P (.clk(clk), .reset(reset), .data_in(Ip), .ms_interrupt(dump_aligned), .ACCUMDATA(I_prompt));
    accumulator_1ms ACC_I_L (.clk(clk), .reset(reset), .data_in(Il), .ms_interrupt(dump_aligned), .ACCUMDATA(I_late));
    accumulator_1ms ACC_Q_P (.clk(clk), .reset(reset), .data_in(Qp), .ms_interrupt(dump_aligned), .ACCUMDATA(Q_prompt));
    accumulator_1ms ACC_Q_L (.clk(clk), .reset(reset), .data_in(Ql), .ms_interrupt(dump_aligned), .ACCUMDATA(Q_late));

endmodule
