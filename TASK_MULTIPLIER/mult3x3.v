// =================================================================
// Module: mult3x3 (synchronous version)
// Description: Multiplies two 3-bit signed inputs using a
//              sign-magnitude approach, producing a 4-bit
//              sign-magnitude output. Per supervisor's request,
//              this is now a SYNCHRONOUS (clocked) module so it can
//              be integrated into the main pipeline: the result is
//              registered (updates only on posedge clk) and clears
//              to 0 on reset, keeping it in step with the rest of
//              the pipeline.
//              p[3]   = sign bit (0=positive, 1=negative)
//              p[2:0] = truncated magnitude
// =================================================================
module mult3x3 (
    input  wire              clk,     // pipeline clock
    input  wire              reset,   // synchronous reset
    input  wire signed [2:0] a,       // 3-bit signed input  (-4 to +3)
    input  wire signed [2:0] b,       // 3-bit signed input  (-4 to +3)
    output reg         [3:0] p        // 4-bit SIGN-MAGNITUDE output (registered)
);

    // ---- combinational sign-magnitude multiply (same math as before) ----
    wire sign_a = a[2];
    wire sign_b = b[2];
    wire [2:0] mag_a = sign_a ? (~a + 3'b001) : a;
    wire [2:0] mag_b = sign_b ? (~b + 3'b001) : b;
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
