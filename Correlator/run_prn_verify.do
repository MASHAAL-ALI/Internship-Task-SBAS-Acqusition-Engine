# =================================================================
# ModelSim .do script for the STANDALONE PRN1 alignment verification
# (separate from run_top_system.do -- does not touch tb_top_system)
# Usage: do run_prn_verify.do
# Assumes all .v files below are in the same folder as this .do file.
# =================================================================

# ---- clean rebuild ----
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

# ---- compile only what's needed for this check, in dependency order ----
vlog prn_selector.v
vlog gps_code_nco.v
vlog prn_code_gen_up.v
vlog if_prn1_golden_ref.v
vlog tb_prn_verify.v

# ---- load simulation ----
vsim -voptargs=+acc work.tb_prn_verify

# ---- waveform: exactly what the supervisor asked to see ----
add wave -divider "Shared clock / reset"
add wave -radix binary   /tb_prn_verify/clk
add wave -radix binary   /tb_prn_verify/reset
add wave -radix binary   /tb_prn_verify/code_tick

add wave -divider "DUT (prn_code_gen) vs GOLDEN (if_prn1_golden_ref)"
add wave -radix binary   /tb_prn_verify/chip_bit_dut
add wave -radix binary   /tb_prn_verify/chip_bit_ref

add wave -divider "Mismatch counters"
add wave -radix decimal  /tb_prn_verify/compare_count
add wave -radix decimal  /tb_prn_verify/mismatch_count

# ---- run full test + fit waveform ----
run -all
wave zoom full
