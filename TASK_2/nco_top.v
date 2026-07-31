// =================================================================
// Module: nco_top
// Description: GPS L1 IF Carrier NCO -- single, self-contained module
//              (phase accumulator + sine lookup merged in, per
//              supervisor's request, for easier reuse in future tasks)
//
// Fclk = 16.368 MHz, Fout = 4.092 MHz => Fclk/Fout = exactly 4
// I_out (cosine) and Q_out (sine) are now 3-bit signed, per
// supervisor's requested change (previously 12-bit signed).
// =================================================================
module nco_top #(
    parameter ACC_WIDTH      = 32,   // phase accumulator width
    parameter LUT_ADDR_WIDTH = 6,    // 64-entry sine table
    parameter OUT_WIDTH      = 3     // signed sample width (was 12, now 3)
)(
    input  clk,
    input  reset,
    input  [ACC_WIDTH-1:0] phase_step,

    output signed [OUT_WIDTH-1:0] I_out,   // cosine (in-phase)
    output signed [OUT_WIDTH-1:0] Q_out    // sine   (quadrature)
);

    // ---- phase accumulator (was phase_accumulator.v) ----
    reg [ACC_WIDTH-1:0] phase;

    always @(posedge clk) begin
        if (reset)
            phase <= {ACC_WIDTH{1'b0}};
        else
            phase <= phase + phase_step;   // wraps automatically (modulo 2^ACC_WIDTH)
    end

    // ---- LUT addressing: top bits = angle, +quarter-table = +90 deg ----
    wire [LUT_ADDR_WIDTH-1:0] addr_q = phase[ACC_WIDTH-1 -: LUT_ADDR_WIDTH];
    wire [LUT_ADDR_WIDTH-1:0] addr_i = addr_q + (1 << (LUT_ADDR_WIDTH-2));

    // ---- sine lookup (was sine_lut.v) ----
    // 64-entry sine table, one full cycle (0 to 360 degrees).
    // Values scaled to +/-3 (3-bit signed, symmetric full scale).
    // Generated offline from: round(3 * sin(2*pi*addr/64))
    function signed [OUT_WIDTH-1:0] sine_value;
        input [LUT_ADDR_WIDTH-1:0] addr;
        begin
            case(addr)
                6'd0  : sine_value = 3'sd0;
                6'd1  : sine_value = 3'sd0;
                6'd2  : sine_value = 3'sd1;
                6'd3  : sine_value = 3'sd1;
                6'd4  : sine_value = 3'sd1;
                6'd5  : sine_value = 3'sd1;
                6'd6  : sine_value = 3'sd2;
                6'd7  : sine_value = 3'sd2;
                6'd8  : sine_value = 3'sd2;
                6'd9  : sine_value = 3'sd2;
                6'd10 : sine_value = 3'sd2;
                6'd11 : sine_value = 3'sd3;
                6'd12 : sine_value = 3'sd3;
                6'd13 : sine_value = 3'sd3;
                6'd14 : sine_value = 3'sd3;
                6'd15 : sine_value = 3'sd3;
                6'd16 : sine_value = 3'sd3;
                6'd17 : sine_value = 3'sd3;
                6'd18 : sine_value = 3'sd3;
                6'd19 : sine_value = 3'sd3;
                6'd20 : sine_value = 3'sd3;
                6'd21 : sine_value = 3'sd3;
                6'd22 : sine_value = 3'sd2;
                6'd23 : sine_value = 3'sd2;
                6'd24 : sine_value = 3'sd2;
                6'd25 : sine_value = 3'sd2;
                6'd26 : sine_value = 3'sd2;
                6'd27 : sine_value = 3'sd1;
                6'd28 : sine_value = 3'sd1;
                6'd29 : sine_value = 3'sd1;
                6'd30 : sine_value = 3'sd1;
                6'd31 : sine_value = 3'sd0;
                6'd32 : sine_value = 3'sd0;
                6'd33 : sine_value = 3'sd0;
                6'd34 : sine_value = -3'sd1;
                6'd35 : sine_value = -3'sd1;
                6'd36 : sine_value = -3'sd1;
                6'd37 : sine_value = -3'sd1;
                6'd38 : sine_value = -3'sd2;
                6'd39 : sine_value = -3'sd2;
                6'd40 : sine_value = -3'sd2;
                6'd41 : sine_value = -3'sd2;
                6'd42 : sine_value = -3'sd2;
                6'd43 : sine_value = -3'sd3;
                6'd44 : sine_value = -3'sd3;
                6'd45 : sine_value = -3'sd3;
                6'd46 : sine_value = -3'sd3;
                6'd47 : sine_value = -3'sd3;
                6'd48 : sine_value = -3'sd3;
                6'd49 : sine_value = -3'sd3;
                6'd50 : sine_value = -3'sd3;
                6'd51 : sine_value = -3'sd3;
                6'd52 : sine_value = -3'sd3;
                6'd53 : sine_value = -3'sd3;
                6'd54 : sine_value = -3'sd2;
                6'd55 : sine_value = -3'sd2;
                6'd56 : sine_value = -3'sd2;
                6'd57 : sine_value = -3'sd2;
                6'd58 : sine_value = -3'sd2;
                6'd59 : sine_value = -3'sd1;
                6'd60 : sine_value = -3'sd1;
                6'd61 : sine_value = -3'sd1;
                6'd62 : sine_value = -3'sd1;
                6'd63 : sine_value = 3'sd0;
                default: sine_value = 3'sd0;
            endcase
        end
    endfunction

    assign Q_out = sine_value(addr_q);   // sine
    assign I_out = sine_value(addr_i);   // cosine (quarter-table ahead)

endmodule
