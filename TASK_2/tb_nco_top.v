`timescale 1ns/1ps
// ============================================================
// Testbench: nco_top (merged, 3-bit signed I/Q version)
//
// Fclk = 16.368 MHz, Fout = 4.092 MHz  =>  Fclk/Fout = exactly 4
// I/Q are now 3-bit signed (range -4..+3), full scale = 3.
//     I (cosine): 3,  0, -3,  0,  3,  0, -3,  0, ...
//     Q (sine)  : 0,  3,  0, -3,  0,  3,  0, -3, ...
// ============================================================
module tb_nco_top;

    localparam ACC_WIDTH      = 32;
    localparam LUT_ADDR_WIDTH = 6;
    localparam OUT_WIDTH      = 3;
    localparam FS             = 3;    // full scale for 3-bit signed

    // phase_step = 2^ACC_WIDTH * (Fout/Fclk) = 2^32 * (1/4) = 2^30
    localparam [ACC_WIDTH-1:0] PHASE_STEP = 32'd1073741824;

    reg clk;
    reg reset;
    wire signed [OUT_WIDTH-1:0] I_out;
    wire signed [OUT_WIDTH-1:0] Q_out;

    integer i;
    integer errors;

    reg signed [OUT_WIDTH-1:0] expected_I [0:3];
    reg signed [OUT_WIDTH-1:0] expected_Q [0:3];

    nco_top #(
        .ACC_WIDTH(ACC_WIDTH),
        .LUT_ADDR_WIDTH(LUT_ADDR_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .phase_step(PHASE_STEP),
        .I_out(I_out),
        .Q_out(Q_out)
    );

    always #5 clk = ~clk;

    initial begin
        expected_I[0] =  FS;  expected_Q[0] =   0;
        expected_I[1] =    0; expected_Q[1] =  FS;
        expected_I[2] = -FS;  expected_Q[2] =   0;
        expected_I[3] =    0; expected_Q[3] = -FS;
    end

    initial begin
        clk    = 0;
        reset  = 1;
        errors = 0;

        @(posedge clk);
        @(posedge clk);
        reset = 0;
        #1;

        $display("=========================================================");
        $display(" NCO verification (3-bit signed I/Q): 4 samples per cycle");
        $display("=========================================================");

        for (i = 0; i < 12; i = i + 1) begin
            #1;
            $display("sample %0d : I=%0d  Q=%0d   (expected I=%0d Q=%0d)",
                       i, I_out, Q_out, expected_I[i%4], expected_Q[i%4]);

            if (I_out !== expected_I[i%4] || Q_out !== expected_Q[i%4]) begin
                $display("   ^^^ MISMATCH at sample %0d", i);
                errors = errors + 1;
            end

            @(posedge clk);
        end

        $display("=========================================================");
        if (errors == 0)
            $display(" SELF-CHECK PASS: all 12 samples matched exactly.");
        else
            $display(" SELF-CHECK FAIL: %0d mismatches found.", errors);
        $display("=========================================================");

        $stop;
    end

endmodule
