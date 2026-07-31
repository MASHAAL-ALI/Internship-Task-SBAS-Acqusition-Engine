// =================================================================
// Module Name: gps_code_nco
// Description: Generates a 2.046 MHz code_tick from a 16.368 MHz clock
//              Ratio is exactly 8 (16.368 / 2.046 = 8)
// =================================================================

module gps_code_nco #(
    parameter PHASE_WIDTH = 32
)(
    input  wire clk,       // System Clock: 16.368 MHz
    input  wire rst,       // Synchronous Reset
    output reg  code_tick  // One-clock-cycle pulse at 2.046 MHz
);

    // Frequency Tuning Word (FTW) for exact divide-by-8
    // Formula: (2^32 / 8) = 536870912 => 32'h2000_0000
    // Pure Verilog shifting method for localparam
    localparam [PHASE_WIDTH-1:0] FTW = (32'b1 << (PHASE_WIDTH - 3));

    reg [PHASE_WIDTH-1:0] phase_acc;

    always @(posedge clk) begin
        if (rst) begin
            phase_acc <= 0;
            code_tick <= 1'b0;
        end else begin
            phase_acc <= phase_acc + FTW;
            
            // Check for overflow/carry-out condition
            // In exact div-by-8, when phase_acc is at its max state, 
            // adding FTW will cause a roll-over to 0.
            if ((phase_acc + FTW) < phase_acc) begin
                code_tick <= 1'b1;
            end else begin
                code_tick <= 1'b0;
            end
        end
    end

endmodule
