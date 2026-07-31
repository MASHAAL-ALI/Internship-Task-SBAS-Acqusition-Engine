`timescale 1ns/1ps
// ============================================================
// Testbench: accumulator_1ms (external ms_interrupt version)
//
// The testbench itself now generates the "ms_interrupt" pulse --
// a counter here counts 16368 clock ticks, then pulses
// ms_interrupt high for exactly 1 clock, telling the DUT
// "this is the last tick of the 1ms window". The DUT no longer
// does any of this counting itself.
//
// Two cases are tested:
//   1. data_in = 1 (normal, realistic case)   -> no overflow
//   2. data_in = 3 (fixed worst-case stress test) -> overflow/wrap
// ============================================================
module tb_accumulator_1ms;

    localparam TICKS_PER_MS = 16368;

    reg clk;
    reg reset;
    reg signed [3:0] data_in;
    wire signed [15:0] ACCUMDATA;

    // ---- ms_interrupt generator (this lives in the testbench now) ----
    reg [14:0] ms_count;
    reg        ms_interrupt;

    always @(posedge clk) begin
        if (reset) begin
            ms_count     <= 15'd0;
            ms_interrupt <= 1'b0;
        end else if (ms_count == TICKS_PER_MS - 1) begin
            ms_count     <= 15'd0;
            ms_interrupt <= 1'b1;   // pulse high for exactly this one clock
        end else begin
            ms_count     <= ms_count + 1'b1;
            ms_interrupt <= 1'b0;
        end
    end

    accumulator_1ms DUT (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .ms_interrupt(ms_interrupt),
        .ACCUMDATA(ACCUMDATA)
    );

    always #5 clk = ~clk;

    integer w;
    reg signed [15:0] expected;

    task run_case;
        input signed [3:0] test_value;
        input signed [15:0] expected_value;
        begin
            data_in  = test_value;
            expected = expected_value;

            reset = 1;
            @(posedge clk);
            @(posedge clk);
            reset = 0;

            for (w = 1; w <= 3; w = w + 1) begin
                repeat (TICKS_PER_MS) @(posedge clk);
                #1;
                $display("data_in=%0d  window %0d : ACCUMDATA = %0d   expected = %0d   %s",
                           test_value, w, ACCUMDATA, expected,
                           (ACCUMDATA === expected) ? "MATCH" : "MISMATCH");
            end
        end
    endtask

    initial begin
        clk = 0;

        $display("=========================================================");
        $display(" accumulator_1ms demo (external ms_interrupt)");
        $display("=========================================================");

        $display("--- Case 1: normal value, data_in = 1 (no overflow expected) ---");
        run_case(4'sd1, 16'sd16368);

        $display("--- Case 2: stress value, data_in = 3 (overflow/wrap expected) ---");
        run_case(4'sd3, -16'sd16432);

        $display("=========================================================");
        $stop;
    end

endmodule
