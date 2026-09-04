# =================================================================
# ModelSim .do script for the full GPS channel system
# Usage: at the ModelSim "ModelSim>" prompt (or Tools -> Execute Macro):
#   do run_top_system.do
# Assumes all .v files listed below are in the SAME folder as this
# .do file, or edit the paths to match your project folder.
# =================================================================

# ---- clean rebuild ----
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

# ---- compile in dependency order ----
vlog prn_selector.v
vlog nco_top.v
vlog gps_code_nco.v
vlog prn_code_gen_up.v
vlog mult3x3.v
vlog mult4x2.v
vlog sm2tc.v
vlog accumulator_1ms.v
vlog gps_channel.v
vlog if_stimulus_gen.v
vlog top_system.v
vlog tb_top_system.v

# ---- load simulation ----
vsim -voptargs=+acc work.tb_top_system

# ---- waveform: final outputs + PRN control ----
add wave -divider "Control / final outputs"
add wave -radix decimal                /tb_top_system/prn_no
add wave -radix decimal -signed         /tb_top_system/I_prompt
add wave -radix decimal -signed         /tb_top_system/I_late
add wave -radix decimal -signed         /tb_top_system/Q_prompt
add wave -radix decimal -signed         /tb_top_system/Q_late
add wave -radix decimal                 /tb_top_system/dump_out

# ---- waveform: IF module raw output ----
add wave -divider "IF module (sign-magnitude)"
add wave -radix binary                  /tb_top_system/if_sign
add wave -radix binary                  /tb_top_system/if_mag
add wave -radix binary                  /tb_top_system/L1

# ---- waveform: gps_channel intermediate stages ----
add wave -divider "gps_channel intermediate stages"
add wave -radix decimal -signed         /tb_top_system/ILO
add wave -radix decimal -signed         /tb_top_system/QLO
add wave -radix decimal -signed         /tb_top_system/if_monitor
add wave -radix decimal -signed         /tb_top_system/prompt
add wave -radix decimal -signed         /tb_top_system/late
add wave -radix decimal                 /tb_top_system/dump
add wave -radix decimal                 /tb_top_system/code_tick
add wave -radix decimal                 /tb_top_system/chip_en
add wave -radix decimal                 /tb_top_system/chip_bit

# ---- run full sweep (32 PRNs, ~64ms simulated time) ----
run -all

# ---- fit the whole capture in the Wave window ----
wave zoom full
