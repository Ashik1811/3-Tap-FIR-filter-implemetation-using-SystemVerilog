
# 3-Tap FIR Filter Design

## Project Overview
This project implements a 3-Tap Finite Impulse Response (FIR) Filter using SystemVerilog HDL.

The design performs digital filtering using three coefficients and a delay-line architecture.

## Objectives
- Design a 3-Tap FIR Filter.
- Implement the RTL using SystemVerilog.
- Verify the functionality using a testbench.
- Perform logic simulation.
- Perform RTL synthesis.

## Architecture
The FIR filter is based on the following equation:

y[n] = h[0]x[n] + h[1]x[n-1] + h[2]x[n-2]

Where:
- x[n] = Current input sample
- h[0], h[1], h[2] = Filter coefficients
- y[n] = Filter output


## Tools and Technologies
- SystemVerilog
- RTL Design
- Functional Verification
- Logic Simulation
- RTL Synthesis

