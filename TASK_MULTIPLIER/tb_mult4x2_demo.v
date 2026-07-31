`timescale 1ns/1ps
// ============================================================
// Demo testbench for mult4x2 (synchronous version)
// ============================================================
module tb_mult4x2;

    reg clk;
    reg reset;
    reg  signed [3:0] a;
    reg  signed [1:0] b;
    wire        [3:0] p;

    integer decimal_answer;

    mult4x2 DUT (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .p(p)
    );

    always #5 clk = ~clk;

    task show_result;
        input signed [3:0] ta;
        input signed [1:0] tb;
        begin
            a = ta;
            b = tb;
            @(posedge clk);
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
        $display(" mult4x2 demo (synchronous, sign-magnitude): a x b = answer");
        $display("===============================================================================");

        show_result(5, 1);
        show_result(-5, 1);
        show_result(3, -2);
        show_result(-8, -2);
        show_result(7, 1);
        show_result(0, -2);

        $display("===============================================================================");
        $stop;
    end

endmodule
