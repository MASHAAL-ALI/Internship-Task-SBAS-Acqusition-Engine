module prn_selector(

    input  [5:0] prn_select,
    input  [9:0] g2_state,

    output reg g2_selected

);

// Table 2.3 - C/A code phase assignment (Parkinson/Spilker style GPS reference)
// g2_state[k] below represents "cell k+1" in the book's 1-indexed cell numbering,
// e.g. cell 2 -> g2_state[1], cell 6 -> g2_state[5], cell 10 -> g2_state[9].

always @(*) begin

    case(prn_select)

        // PRN 1  (G2 taps 2 & 6)
        6'd1:  g2_selected = g2_state[1] ^ g2_state[5];
        // PRN 2  (G2 taps 3 & 7)
        6'd2:  g2_selected = g2_state[2] ^ g2_state[6];
        // PRN 3  (G2 taps 4 & 8)
        6'd3:  g2_selected = g2_state[3] ^ g2_state[7];
        // PRN 4  (G2 taps 5 & 9)
        6'd4:  g2_selected = g2_state[4] ^ g2_state[8];
        // PRN 5  (G2 taps 1 & 9)
        6'd5:  g2_selected = g2_state[0] ^ g2_state[8];
        // PRN 6  (G2 taps 2 & 10)
        6'd6:  g2_selected = g2_state[1] ^ g2_state[9];
        // PRN 7  (G2 taps 1 & 8)
        6'd7:  g2_selected = g2_state[0] ^ g2_state[7];
        // PRN 8  (G2 taps 2 & 9)
        6'd8:  g2_selected = g2_state[1] ^ g2_state[8];
        // PRN 9  (G2 taps 3 & 10)
        6'd9:  g2_selected = g2_state[2] ^ g2_state[9];
        // PRN 10 (G2 taps 2 & 3)
        6'd10: g2_selected = g2_state[1] ^ g2_state[2];
        // PRN 11 (G2 taps 3 & 4)
        6'd11: g2_selected = g2_state[2] ^ g2_state[3];
        // PRN 12 (G2 taps 5 & 6)
        6'd12: g2_selected = g2_state[4] ^ g2_state[5];
        // PRN 13 (G2 taps 6 & 7)
        6'd13: g2_selected = g2_state[5] ^ g2_state[6];
        // PRN 14 (G2 taps 7 & 8)
        6'd14: g2_selected = g2_state[6] ^ g2_state[7];
        // PRN 15 (G2 taps 8 & 9)
        6'd15: g2_selected = g2_state[7] ^ g2_state[8];
        // PRN 16 (G2 taps 9 & 10)
        6'd16: g2_selected = g2_state[8] ^ g2_state[9];
        // PRN 17 (G2 taps 1 & 4)
        6'd17: g2_selected = g2_state[0] ^ g2_state[3];
        // PRN 18 (G2 taps 2 & 5)
        6'd18: g2_selected = g2_state[1] ^ g2_state[4];
        // PRN 19 (G2 taps 3 & 6)
        6'd19: g2_selected = g2_state[2] ^ g2_state[5];
        // PRN 20 (G2 taps 4 & 7)
        6'd20: g2_selected = g2_state[3] ^ g2_state[6];
        // PRN 21 (G2 taps 5 & 8)
        6'd21: g2_selected = g2_state[4] ^ g2_state[7];
        // PRN 22 (G2 taps 6 & 9)
        6'd22: g2_selected = g2_state[5] ^ g2_state[8];
        // PRN 23 (G2 taps 1 & 3)
        6'd23: g2_selected = g2_state[0] ^ g2_state[2];
        // PRN 24 (G2 taps 4 & 6)
        6'd24: g2_selected = g2_state[3] ^ g2_state[5];
        // PRN 25 (G2 taps 5 & 7)
        6'd25: g2_selected = g2_state[4] ^ g2_state[6];
        // PRN 26 (G2 taps 6 & 8)
        6'd26: g2_selected = g2_state[5] ^ g2_state[7];
        // PRN 27 (G2 taps 7 & 9)
        6'd27: g2_selected = g2_state[6] ^ g2_state[8];
        // PRN 28 (G2 taps 8 & 10)
        6'd28: g2_selected = g2_state[7] ^ g2_state[9];
        // PRN 29 (G2 taps 1 & 6)
        6'd29: g2_selected = g2_state[0] ^ g2_state[5];
        // PRN 30 (G2 taps 2 & 7)
        6'd30: g2_selected = g2_state[1] ^ g2_state[6];
        // PRN 31 (G2 taps 3 & 8)
        6'd31: g2_selected = g2_state[2] ^ g2_state[7];
        // PRN 32 (G2 taps 4 & 9)
        6'd32: g2_selected = g2_state[3] ^ g2_state[8];
        // PRN 33 (signal 33, G2 taps 5 & 10) - reserved / ground use
        6'd33: g2_selected = g2_state[4] ^ g2_state[9];
        // PRN 34 (signal 34, G2 taps 4 & 10) - reserved / ground use (identical to 37)
        6'd34: g2_selected = g2_state[3] ^ g2_state[9];
        // PRN 35 (signal 35, G2 taps 1 & 7) - reserved / ground use
        6'd35: g2_selected = g2_state[0] ^ g2_state[6];
        // PRN 36 (signal 36, G2 taps 2 & 8) - reserved / ground use
        6'd36: g2_selected = g2_state[1] ^ g2_state[7];
        // PRN 37 (signal 37, G2 taps 4 & 10) - reserved / ground use (identical to 34)
        6'd37: g2_selected = g2_state[3] ^ g2_state[9];

        default: g2_selected = g2_state[1] ^ g2_state[5]; // fall back to PRN1

    endcase

end

endmodule
