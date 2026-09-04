// =================================================================
// Module Name: gps_code_nco
// Description: Generates a 2.046 MHz code_tick from a 16.368 MHz clock
//              Ratio is exactly 8 (16.368 / 2.046 = 8)
// =================================================================

module gps_code_nco #(
    parameter PHASE_WIDTH = 32
)(
    input  wire clk,                        // System Clock: 16.368 MHz
    input  wire rst,                        // Synchronous Reset
    input  wire [PHASE_WIDTH-1:0] phase_step, // Runtime-tunable FTW (Doppler control).
                                              // Nominal (zero-Doppler) value = 32'h2000_0000
                                              // -> exact divide-by-8 -> 2.046 MHz code_tick
    output reg  code_tick  // One-clock-cycle pulse at nominal 2.046 MHz
);

    reg [PHASE_WIDTH-1:0] phase_acc;

    always @(posedge clk) begin
        if (rst) begin
            phase_acc <= 0;
            code_tick <= 1'b0;
        end else begin
            phase_acc <= phase_acc + phase_step;

            // Carry-out (overflow) detection = one code_tick pulse
            if ((phase_acc + phase_step) < phase_acc) begin
                code_tick <= 1'b1;
            end else begin
                code_tick <= 1'b0;
            end
        end
    end

endmodule
