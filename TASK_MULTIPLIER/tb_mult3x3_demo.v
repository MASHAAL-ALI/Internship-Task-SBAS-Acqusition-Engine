`timescale 1ns/1ps
// ============================================================
// Demo testbench for mult3x3 (synchronous version)
// Since the DUT now registers its output, we must apply a, b,
// then wait for ONE clock edge before the result p is valid --
// unlike the old combinational version where p updated instantly.
// ============================================================
module tb_mult3x3;

    reg clk;
    reg reset;
    reg  signed [2:0] a, b;
    wire        [3:0] p;

    integer decimal_answer;

    mult3x3 DUT (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .p(p)
    );

    always #5 clk = ~clk;

    task show_result;
        input signed [2:0] ta, tb;
        begin
            a = ta;
            b = tb;
            @(posedge clk);   // <-- wait for the register to update
            #1;
            if (p[3] == 1'b1)
                decimal_answer = -p[2:0];
            else
                decimal_answer = p[2:0];

            $display("a = %b (%0d) , b = %b (%0d)  ->  p = %b  [sign=%b mag=%b]  =>  answer = %0d",
                       ta, ta, tb, tb, p, p[3], p[2:0], decimal_answer);
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        a = 0; b = 0;
        @(posedge clk);
        @(posedge clk);
        reset = 0;

        $display("===============================================================================");
        $display(" mult3x3 demo (synchronous, sign-magnitude): a x b = answer");
        $display("===============================================================================");

        show_result(3, 2);
        show_result(-3, 2);
        show_result(2, -3);
        show_result(-4, -4);
        show_result(1, 1);
        show_result(0, 3);

        $display("===============================================================================");
        $stop;
    end

endmodule
