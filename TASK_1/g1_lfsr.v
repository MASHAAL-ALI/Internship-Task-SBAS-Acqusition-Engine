module g1_lfsr(
    input clk,
    input reset,
    output wire g1_out,
    output wire [9:0] g1_state
);

    // 10-bit Shift Register
    reg [9:0] g1;

    // Feedback Calculation
    // Polynomial: x^10 + x^3 + 1
    // Standard notation: Feedback comes from cell 10 and cell 3
    // cell 10 -> g1[9], cell 3 -> g1[2]
    wire feedback;
    assign feedback = g1[9] ^ g1[2];

    // Output: cell 10 becomes the output bit
    assign g1_out = g1[9];
    assign g1_state = g1;

    // Shift Register (Corrected Shift Direction)
    always @(posedge clk or posedge reset) begin
        if(reset)
            g1 <= 10'b1111111111;
        else
            g1 <= {g1[8:0], feedback}; // ? Sahi direction: Naya bit index 0 mein jata hai
    end

endmodule
