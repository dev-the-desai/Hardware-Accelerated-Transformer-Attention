# Hardware-Accelerated-Transformer-Attention
A SystemVerilog implementation of the Scaled Dot-Product Attention mechanism for transformer neural networks, featuring pipelined matrix multiplication and SRAM-based memory architecture.

## Project Overview
This project implements the core self-attention computation block of a transformer neural network in hardware. It performs the complete scaled dot-product attention calculation: (QK<sup>T</sup>)V, including the matrix multiplications for generating Query (Q), Key (K), and Value (V) matrices from input embeddings.

## Key Implementation Features
1. Matrix Operations
    * Input embedding matrix multiplication (I × W<sub>Q</sub>, I × W<sub>K</sub>, I × W<sub>V</sub>)
    * Key matrix transposition (K<sup>T</sup>)
    * Score matrix computation (Q × K<sup>T</sup>)
    * Final attention value calculation (Score × V)

2. Memory Architecture
    * Three SRAM interfaces (Input, Weight, Result)
    * Single-cycle access latency
    * Word-addressable storage
    * Pipeline-aware data forwarding

3. Hardware Features
    * Fully pipelined design
    * Handshake-based control protocol
    * Parameterized matrix dimensions
    * Reset synchronization

<div align="center">
<img width="600" alt="Timing behaviour" src="https://github.com/user-attachments/assets/c34a2fde-1647-4e90-b805-aef992457530">
<p><strong>Figure 1:</strong> Matrices Multpilied </p>
</div>

## Technical Details

### Interface Signals
System Signals:

* clk: System clock
* reset_n: Active-low reset

Control Signals:

* dut_valid: Input data validity signal
* dut_ready: Processing ready status

SRAM Interface:

* Read/Write address buses
* Data input/output buses
* Write enable control
* Read/Write select

<div align="center">
<img width="600" alt="Timing behaviour" src="https://github.com/user-attachments/assets/184ad84d-f4bf-40ac-ad30-6de5839240a8">
<p><strong>Figure 1:</strong> Timing Behavior</p>
</div>

### Memory Organization
SRAM Input:

* Address 0x000: Matrix dimensions
* Address 0x001-0x040: Input embedding matrix (I)

SRAM Weight:

* Address 0x000: Matrix dimensions
* Address 0x001-0x100: Query weights (W<sub>Q</sub>)
* Address 0x101-0x200: Key weights (W<sub>K</sub>)
* Address 0x201-0x300: Value weights (W<sub>V</sub>)

SRAM Result:

* Address 0x000-0x03F: Query matrix (Q)
* Address 0x040-0x07F: Key matrix (K)
* Address 0x080-0x0BF: Value matrix (V)
* Address 0x0C0-0x0CF: Score matrix (S)
* Address 0x0D0-0x10F: Final attention output (Z)

## Implementation Notes
* Synchronous reset implementation
* Pipelined matrix multiplication
* RAW hazard management for SRAM access
* Synthesizable SystemVerilog design
* Handshake-based control flow

## Project Requirements
* SystemVerilog compatible simulator (ModelSim/QuestaSim)
* Synopsys Design Compiler for synthesis
* Standard cell library

## Build and Simulation
Compilation:
```
vlog dut.sv testbench.sv
```

Simulation:
```
vsim -c testbench
run -all
```

View Waveforms:
```
vsim testbench
add wave -r /*
run -all
```
