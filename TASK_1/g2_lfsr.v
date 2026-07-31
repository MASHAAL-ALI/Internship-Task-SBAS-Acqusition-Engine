module g2_lfsr(
    input clk,
    input reset,
    output wire g2_out,
    output wire [9:0] g2_state
);

    // 10-bit Shift Register
    reg [9:0] g2;

    // Feedback Calculation
    // Polynomial: x^10 + x^9 + x^8 + x^6 + x^3 + x^2 + 1
    wire feedback;
    assign feedback = g2[9] ^
                      g2[8] ^
                      g2[7] ^
                      g2[5] ^
                      g2[2] ^
                      g2[1];

    // Outputs
    assign g2_out = g2[9];
    assign g2_state = g2;

    // Shift Register (Corrected Shift Direction)
    always @(posedge clk or posedge reset) begin
        if(reset)
            g2 <= 10'b1111111111;
        else
            g2 <= {g2[8:0], feedback}; // ? Sahi direction: Naya bit index 0 mein jata hai
    end

endmodule
