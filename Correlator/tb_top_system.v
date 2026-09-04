`timescale 1ns/1ps
// =================================================================
// Testbench: tb_top_system
// Purpose: Test the FINAL TOP MODULE (top_system) end to end, pure
//          simulation only (no Block Design / no hardware).
//
//          Sweeps prn_no from 1 to 32. IF module is internally fixed
//          to PRN 1, zero Doppler -- so gps_channel should show a
//          correlation PEAK only when prn_no == 1, and LOW values for
//          every other PRN (2..32).
// =================================================================
module tb_top_system;

    reg         clk;
    reg         reset;
    reg [31:0]  carrier_nco;
    reg [31:0]  code_nco;
    reg [5:0]   prn_no;

    wire         if_sign;
    wire [1:0]   if_mag;
    wire [2:0]   L1;
    wire signed [2:0] ILO, QLO, if_monitor;
    wire signed [1:0] prompt, late;
    wire         dump, dump_out, code_tick, chip_en, chip_bit;
    wire signed [15:0] I_prompt, I_late, Q_prompt, Q_late;

    top_system DUT (
        .clk        (clk),
        .reset      (reset),
        .carrier_nco(carrier_nco),
        .code_nco   (code_nco),
        .prn_no     (prn_no),
        .if_sign    (if_sign),
        .if_mag     (if_mag),
        .L1         (L1),
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

    // 16.368 MHz system clock -> period ~= 61.0973 ns
    localparam real CLK_PERIOD = 61.0973;
    initial clk = 1'b0;
    always #(CLK_PERIOD/2.0) clk = ~clk;

    // Matched (PRN1) autocorrelation peak ~8184; cross-correlation with
    // other PRNs stays well below this -- see report for the math.
    localparam integer PEAK_THRESHOLD = 2000;

    integer p;
    integer fail_count;

    initial begin
        reset       = 1'b1;
        carrier_nco = 32'h4000_0000;  // nominal 4.092 MHz, zero Doppler
        code_nco    = 32'h2000_0000;  // nominal 2.046 MHz, zero Doppler
        prn_no      = 6'd1;
        fail_count  = 0;
        repeat (5) @(posedge clk);
        reset = 1'b0;

        $display("================================================================");
        $display(" top_system full sweep -- IF module fixed to PRN 1, zero Doppler");
        $display(" carrier_nco = 32'h%08h   code_nco = 32'h%08h", carrier_nco, code_nco);
        $display("================================================================");

        for (p = 1; p <= 32; p = p + 1) begin
            prn_no = p[5:0];

            @(posedge dump_out);   // flush any partial epoch from previous PRN
            @(posedge dump_out);   // this epoch is now fully settled on prn_no

            if ((I_prompt > PEAK_THRESHOLD) || (I_prompt < -PEAK_THRESHOLD)) begin
                if (p == 1)
                    $display("prn_no=%0d (%06b) -> I_prompt=%0d  I_late=%0d  Q_prompt=%0d  Q_late=%0d  ==> HIGH/PEAK (expected)", p, p, I_prompt, I_late, Q_prompt, Q_late);
                else begin
                    $display("prn_no=%0d (%06b) -> I_prompt=%0d  I_late=%0d  Q_prompt=%0d  Q_late=%0d  ==> HIGH/PEAK *** UNEXPECTED ***", p, p, I_prompt, I_late, Q_prompt, Q_late);
                    fail_count = fail_count + 1;
                end
            end else begin
                if (p == 1) begin
                    $display("prn_no=%0d (%06b) -> I_prompt=%0d  I_late=%0d  Q_prompt=%0d  Q_late=%0d  ==> low *** UNEXPECTED, PRN1 SHOULD PEAK ***", p, p, I_prompt, I_late, Q_prompt, Q_late);
                    fail_count = fail_count + 1;
                end else
                    $display("prn_no=%0d (%06b) -> I_prompt=%0d  I_late=%0d  Q_prompt=%0d  Q_late=%0d  ==> low (expected)", p, p, I_prompt, I_late, Q_prompt, Q_late);
            end
        end

        $display("================================================================");
        if (fail_count == 0)
            $display(" RESULT: PASS -- only prn_no=1 produced a correlation peak.");
        else
            $display(" RESULT: FAIL -- %0d unexpected result(s), see *** lines above.", fail_count);
        $display("================================================================");

        $finish;
    end

endmodule
