# GPS L1 C/A Channel — Full System Simulation Report

## 1. What was built and how it is organized

The design has three levels, exactly as specified:

1. **`gps_channel`** — the receiver's correlator core. Contains the carrier NCO,
   code NCO, PRN (Gold code) generator, carrier wipe-off multipliers, despreading
   multipliers, and 1ms coherent accumulators. It does **not** generate its own
   IF sample — that is supplied to it from outside.
2. **`if_stimulus_gen`** ("the IF module") — a self-contained stand-in for a
   satellite signal. It has its own carrier NCO, code NCO, and PRN generator,
   permanently fixed to **PRN 1** with **zero Doppler** on both carrier and
   code. It outputs the IF sample in **sign-magnitude** format, split into
   `if_sign` (1 bit) and `if_mag` (2 bits), concatenated into `L1` (3 bits).
3. **`top_system`** — the actual top module. Instantiates `if_stimulus_gen` and
   `gps_channel` as two independent siblings and wires them together:
   `if_stimulus_gen`'s `L1` output feeds (through a small sign-magnitude to
   two's-complement converter, `sm2tc`) into `gps_channel`'s `if_sample` input.

```
if_stimulus_gen  --L1(sign-mag)-->  sm2tc  --if_sample(two's-comp)-->  gps_channel
     (PRN 1, zero Doppler)                                          (prn_no = swept 1..32)
```

## 2. Exact inputs given to the system (testbench, tb_top_system.v)

| Signal | Value given | Meaning |
|---|---|---|
| clk | 16.368 MHz (period 61.0973 ns) | single system clock domain, everything runs off this one clock |
| reset | held high 5 clk cycles at start | synchronous reset for every sub-block |
| carrier_nco | 32'h4000_0000 (1,073,741,824) | frequency word for gps_channel's carrier NCO -> exactly 4.092 MHz (zero-Doppler). Formula: (4.092/16.368) x 2^32 = 2^32/4 |
| code_nco | 32'h2000_0000 (536,870,912) | frequency word for gps_channel's code NCO -> exactly 2.046 MHz code_tick (zero-Doppler). Formula: 2^32/8 |
| prn_no | swept 1 through 32 | tells gps_channel's PRN generator which Gold code tap-pair to despread with |
| (inside if_stimulus_gen, hardwired) TEST_PRN | 1 | the "satellite" always transmits PRN 1's code |
| (inside if_stimulus_gen, hardwired) CARRIER_PHASE_STEP | 32'h4000_0000 | same 4.092 MHz - satellite and receiver carriers frequency-matched (zero Doppler) |
| (inside if_stimulus_gen, hardwired) CODE_PHASE_STEP | 32'h2000_0000 | same 2.046 MHz - satellite and receiver code timing phase-matched (zero code-phase error) |

Nothing else is given from outside - every other signal (ILO, QLO, L1, prompt,
late, dump, code_tick, chip_en, and the four final outputs) is generated
internally and only exposed for observation.

## 3. Why the final outputs come out the way they do

### 3.1 What each final output physically represents

| Output | What it is |
|---|---|
| I_prompt | In-phase energy accumulated over 1 ms, at exact (on-time) code alignment |
| I_late | In-phase energy, at code alignment delayed by 0.5 chip |
| Q_prompt | Quadrature energy, at exact code alignment |
| Q_late | Quadrature energy, at code alignment delayed by 0.5 chip |

### 3.2 The core mechanism: carrier-squared correlation

Because if_stimulus_gen's carrier and gps_channel's carrier are tuned to the
identical frequency (carrier_nco = CARRIER_PHASE_STEP = 32'h4000_0000) and
both start from reset at the same instant, they stay perfectly phase-locked
to each other for the whole simulation. So the carrier wipe-off stage inside
gps_channel effectively squares the carrier sample:

    Io[n] = if_sample[n] x ILO[n] = (chip_ref[n] x I_ref[n]) x I_ref[n]
          = chip_ref[n] x I_ref[n]^2

I_ref[n]^2 is always positive - only chip_ref[n] (the satellite's own PRN1
chip, bipolar +1/-1) determines the sign. Because the carrier (4.092 MHz) and
chip rate (1.023 MHz) are exact integer multiples of each other (ratio = 4),
the same 16-sample pattern of I_ref^2 repeats identically inside every single
chip period. Call the sum of that repeating pattern S. Then, summed over a
full 1 ms (1023 chips):

    I_prompt = S x ( sum over 1023 chips of  chip_ref[c] x chip_local[c] )

The term in parentheses is exactly the cross-correlation between the
satellite's PRN1 code and the receiver's chosen prn_no code - a pure,
well-defined Gold-code property, nothing else.

### 3.3 The scale factor S

Measured from simulation: prn_no = 1 (autocorrelation, correlation = +1023)
gives I_prompt = 8184. Since 8184 / 1023 = 8, S = 8 exactly.

### 3.4 Gold-code correlation values (why PRN 2-32 all read low)

GPS C/A codes are Gold codes, and Gold-code theory guarantees that the
cross-correlation between any two different codes in the family can only
take one of three fixed values: {-1, -65, +63} (in chip units). Most PRN
pairs land on -1; only a small subset land on the two larger values.
Multiplying by the scale factor S = 8:

| Correlation case | Chip-unit value | I_prompt (x8) |
|---|---|---|
| Autocorrelation (prn_no == 1) | +1023 | +8184 |
| Typical cross-correlation (most other PRNs) | -1 | -8 |
| Occasional cross-correlation (a few specific PRN pairs) | -65 or +63 | -520 or +504 |

This is exactly what the sweep shows: prn_no = 1 reads far above the
PEAK_THRESHOLD = 2000 used in the testbench, and every other PRN reads a
small number close to zero - confirming the despreader is mathematically
correct, not just "roughly working".

### 3.5 Why I_late behaves differently from I_prompt

late is the code replica shifted by 0.5 chip, so its correlation is a mix of
two different-lag correlations (0-chip lag and 1-chip lag), not the single
clean 3-valued number I_prompt gets. That is why I_late varies more from PRN
to PRN than I_prompt does - this is expected, and is in fact the exact
property real GPS tracking loops rely on (the difference between early/late
energy is what tells a tracking loop which direction to nudge the code
phase).

### 3.6 Why Q_prompt / Q_late stay near zero

Q_prompt/Q_late use the carrier's 90-degree-shifted (QLO) component. Since
the satellite's carrier and the receiver's carrier are phase-locked with
zero relative phase offset (zero Doppler, by construction), the I and Q
carrier components stay in quadrature the whole time - meaning the Q
component of a signal that is purely correlated in the I channel averages to
essentially zero. A non-zero Q_prompt would only appear if there were a real
carrier phase/frequency error between the "satellite" and the "receiver" -
which this test deliberately does not have.

## 4. Summary table of the whole run

| prn_no | Expected I_prompt | Reasoning |
|---|---|---|
| 1 | approx +8184 | autocorrelation with the satellite's own PRN1 code |
| 2-32 | small (mostly approx -8, occasionally approx +-500) | Gold-code cross-correlation with a different PRN's code |

## 5. Files in this simulation

| File | Role |
|---|---|
| prn_selector.v | PRN 1-32 tap-select table (Task 1) |
| nco_top.v | carrier NCO, 32-bit phase accumulator + sine LUT (Task 2) |
| gps_code_nco.v | code NCO, now with runtime phase_step input (Task 3, updated) |
| prn_code_gen.v | Gold-code generator producing prompt/late/dump/chip_en |
| mult3x3.v, mult4x2.v | DSP-less signed multipliers (Task 4) |
| sm2tc.v | sign-magnitude to two's-complement converter |
| accumulator_1ms.v | 1ms coherent accumulator (Task 5) |
| if_stimulus_gen.v | the IF module: PRN 1, zero Doppler, sign-magnitude output |
| gps_channel.v | the receiver correlator core |
| top_system.v | the final top module, wiring if_stimulus_gen + gps_channel together |
| tb_top_system.v | testbench: sweeps prn_no 1-32, checks for a single peak at PRN 1 |
| run_top_system.do | ModelSim script: compiles everything in order and runs the sweep |
