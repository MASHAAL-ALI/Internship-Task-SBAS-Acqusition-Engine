module gps_ca_top(

    input clk,
    input reset,
    input [5:0] prn_select,
    output prn_code,
    output [9:0] g1_state,
    output [9:0] g2_state

);
// Internal Signals

wire g1_out;
wire g2_out;
wire g2_selected;

// Instantiate G1
g1_lfsr G1(

    .clk(clk),
    .reset(reset),
    .g1_out(g1_out),
    .g1_state(g1_state)

);
// Instantiate G2
g2_lfsr G2(

    .clk(clk),
    .reset(reset),
    .g2_out(g2_out),
    .g2_state(g2_state)

);
// Instantiate PRN Selector
prn_selector PRN(

    .prn_select(prn_select),
    .g2_state(g2_state),
    .g2_selected(g2_selected)
);

// Generate GPS C/A Chip

assign prn_code = g1_out ^ g2_selected;

endmodule
