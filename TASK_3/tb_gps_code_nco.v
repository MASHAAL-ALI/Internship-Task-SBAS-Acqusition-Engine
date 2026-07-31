`timescale 1ns/1ps
module tb_gps_code_nco;
    // Clock and Reset Signals
    reg clk;
    reg rst;
    wire code_tick;
    // Clock Generation: 16.368 MHz
    // Time Period = 1 / 16.368 MHz = 61.0948 ns => Half period = 30.5474 ns
    always begin
        clk = 1'b0;
        #30.5474;
        clk = 1'b1;
        #30.5474;
    end
    // Instantiate the Unit Under Test (UUT)
    gps_code_nco #(
        .PHASE_WIDTH(32)
    ) uut (
        .clk(clk),
        .rst(rst),
        .code_tick(code_tick)
    );
    // Verification Logic: Counts clock cycles between consecutive code_ticks
    integer clk_count;
    integer tick_num;
    initial begin
        clk_count = 0;
        tick_num = 0;
    end
    // Corrected Block: Using blocking assignments to fix the off-by-one error
    always @(posedge clk) begin
        // NOTE: this #1 is the fix. code_tick is updated by the DUT's own
        // posedge-clk always block using a non-blocking assignment. Without
        // this small delay, this monitor block races with that update and
        // can sample the OLD (pre-edge) value of code_tick instead of the
        // one that was just driven for this clock edge -- causing the very
        // first measured gap to read one cycle too long (9 instead of 8).
        // Waiting 1ns lets the DUT's non-blocking assignment settle first.
        #1;
        if (rst) begin
            clk_count = 0;
        end else begin
            clk_count = clk_count + 1;

            if (code_tick) begin
                tick_num = tick_num + 1;

                // Print and verify the clock count between ticks
                if (clk_count == 8) begin
                    $display("[SUCCESS] Tick #%0d received. Clock cycles since last tick: %0d (Exactly 8). Frequency is perfect!", tick_num, clk_count);
                end else begin
                    $display("[ERROR] Tick #%0d received. Clock cycles since last tick: %0d (Expected: 8!). Timing mismatch!", tick_num, clk_count);
                end

                // Reset counter instantly for the next cycle calculation
                clk_count = 0;
            end
        end
    end
    // Stimulus Process
    initial begin
        $display("---------------------------------------------------------------");
        $display("Starting GPS Code NCO Verification...");
        $display("System Clock: 16.368 MHz | Expected Target: 2.046 MHz (Div-by-8)");
        $display("---------------------------------------------------------------");
        // Apply Synchronous Reset
        rst = 1'b1;
        @(posedge clk);
        @(posedge clk);

        // Release Reset
        rst = 1'b0;
        $display("[STATUS] Reset released. Monitoring code_tick pulses...\n");
        // Run simulation for a few ticks to see the printing
        repeat (10) @(posedge code_tick);
        $display("\n---------------------------------------------------------------");
        $display("Simulation Completed Successfully.");
        $display("---------------------------------------------------------------");
        $finish;
    end
endmodule