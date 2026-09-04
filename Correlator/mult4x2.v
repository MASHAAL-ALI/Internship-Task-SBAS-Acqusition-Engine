// =================================================================
// Module: mult4x2 (synchronous version)
// Description: Multiplies a 4-bit signed input by a 2-bit signed
//              input using a sign-magnitude approach, producing a
//              4-bit sign-magnitude output. Per supervisor's
//              request, this is now a SYNCHRONOUS (clocked) module
//              so it can be integrated into the main pipeline: the
//              result is registered (updates only on posedge clk)
//              and clears to 0 on reset, keeping it in step with
//              the rest of the pipeline.
//              p[3]   = sign bit (0=positive, 1=negative)
//              p[2:0] = truncated magnitude
// =================================================================
module mult4x2 (
    input  wire              clk,     // pipeline clock
    input  wire              reset,   // synchronous reset
    input  wire signed [3:0] a,       // 4-bit signed input (-8 to +7)
    input  wire signed [1:0] b,       // 2-bit signed input (-2 to +1)
    output reg         [3:0] p        // 4-bit SIGN-MAGNITUDE output (registered)
);

    // ---- combinational sign-magnitude multiply (same math as before) ----
    wire sign_a = a[3];
    wire sign_b = b[1];
    wire [3:0] mag_a = sign_a ? (~a + 4'b0001) : a;
    wire [1:0] mag_b = sign_b ? (~b + 2'b01)   : b;
    wire [5:0] full_mag_product = mag_a * mag_b;
    wire [2:0] truncated_mag    = full_mag_product[2:0];
    wire sign_p = sign_a ^ sign_b;
    wire [3:0] p_next = {sign_p, truncated_mag};

    // ---- register the result: this is what makes it synchronous ----
    always @(posedge clk) begin
        if (reset)
            p <= 4'b0000;
        else
            p <= p_next;
    end

endmodule
