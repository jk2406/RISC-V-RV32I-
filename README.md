# RISC-V-RV32I(5 stage Pipelined with hazard detection)




## Overview

This repository contains a **RISC-V CPU** designed with a **5-stage pipeline** and integrated **hazard detection mechanisms**. The CPU is implemented in **SystemVerilog** and can be simulated using **Verilator** along with waveform visualization in **GTKWave**.

## Features

1. **5-Stage Pipeline Architecture**
   The CPU pipeline consists of the following stages:

   * **IF (Instruction Fetch):** Fetches instructions from instruction memory.
   * **ID (Instruction Decode):** Decodes the instruction and reads registers.
   * **EX (Execute):** Performs ALU operations and calculates addresses.
   * **MEM (Memory Access):** Accesses data memory for load/store instructions.
   * **WB (Write Back):** Writes results back to the register file.

2. **Hazard Detection and Forwarding**

   * Supports **data hazards** using forwarding and stalls to maintain correct execution.
   * Handles **control hazards** by introducing pipeline stalls for branches.

3. **Instruction Set Support**

   * Implements a subset of the **RV32I RISC-V instruction set**, covering arithmetic, logical, load/store, and branch instructions.

4. **Simulation and Debugging Support**

   * Fully compatible with **Verilator** for simulation.
   * Generates **VCD files** for waveform analysis using **GTKWave**.

---

## File Structure

Here’s a brief overview of the files in this repository and their purpose:

| File                                 | Description                                                |
| ------------------------------------ | ---------------------------------------------------------- |
| `bin_convertor.exe`                  | Utility to convert binary files for memory initialization. |
| `compile.exe`                        | Helper executable to compile C programs to memory files.   |
| `crt0.o`                             | Startup code object file for bare-metal programs.          |
| `crtO.S`                             | Assembly startup code.                                     |
| `dmem.bin` / `dmem.hex` / `dmem.mem` | Data memory initialization files in different formats.     |
| `dmem_compile.exe`                   | Tool to compile C code into data memory content.           |
| `hello.c`                            | Example C code(Bare Metal) to run on the CPU.              |
| `hello.o` / `hello.elf`              | Compiled object and executable files for the CPU.          |
| `imem.bin` / `imem.hex` / `imem.mem` | Instruction memory files in different formats.             |
| `Dimem_compile.exe`                  | Tool to generate instruction memory files from C code.     |
| `link.ld`                            | Linker script for memory layout during compilation.        |
| `risc.vcd` / `riscw.wcd`             | Waveform dump files for GTKWave visualization.             |
| `RISC_v.sv`                          | Top-level SystemVerilog file of the CPU.                   |
| `tb.sv`                              | Testbench for the CPU simulation.                          |
| `riscv.xdc`                          | Constraints file for FPGA implementation.                  |
| `RISCV_Installation.exe`             | Installer for required tools (if provided).                |
Got it! We can write the **Getting Started** section in a friendly, step-by-step style like you described, guiding the user clearly. Here's a polished version for your documentation:

---

## GETTING STARTED

To get started with this RISC-V 5-stage pipelined CPU, follow these steps carefully.

> **Note:** This setup only works on **Linux**. If you are using **Windows**, you need to enable **WSL (Windows Subsystem for Linux)** or use a Linux virtual machine.

### 1. Install the RISC-V Toolchain

The RISC-V toolchain is required to compile C programs into memory files that can run on your CPU.

1. Download the installer: `RISCV_Installation.exe`  or follow the official instructions from the [RISC-V website](https://riscv.org/software-tools/).
2. Install the toolchain and ensure that `riscv32-unknown-elf-gcc` (or equivalent) is available in your PATH. You can check by running:

```bash
riscv32-unknown-elf-gcc --version
```

You should see the compiler version if the installation was successful.

---

### 2. Prepare Your Workspace

1. Clone or download this repository to your Linux/WSL environment.
2. Navigate to the folder containing the CPU and memory files:

```bash
cd path/to/repository
```

---


## USING THE FILES STEP-BY-STEP

This section explains the role of each file and how to use them effectively to run programs on your RISC-V CPU.

---

### 1. **C Programs (`hello.c`)**

* **Purpose:** Contains the example program you want the CPU to execute.
* **Usage:**

  1. Write your program in C.
  2. Compile it into memory files using the provided tools (`compile.exe`, `dmem_compile.exe`) or the RISC-V GCC toolchain.

```bash
riscv32-unknown-elf-gcc -march=rv32i -mabi=ilp32 -o hello.elf hello.c
```

* **Output:** `hello.elf` (executable), `hello.o` (object file). These are used to generate instruction and data memory contents.

---

### 2. **Startup Code (`crt0.o` and `crtO.S`)**

* **Purpose:** Provides minimal initialization before your C program runs.

  * `crtO.S` – Assembly file that sets up the stack, registers, and calls `main()`.
  * `crt0.o` – Compiled version of `crtO.S`.

* **Usage:** These are automatically linked during compilation of your C program with the linker script (`link.ld`).

---

### 3. **Linker Script (`link.ld`)**

* **Purpose:** Defines the memory layout for your program (where instructions and data reside in memory).
* **Usage:** Used by the linker to generate the `.elf` file from your C program and startup code.

```bash
riscv32-unknown-elf-ld -T link.ld hello.o crt0.o -o hello.elf
```

---

### 4. **Memory Files (`imem.bin`, `imem.hex`, `imem.mem`, `dmem.bin`, `dmem.hex`, `dmem.mem`)**

* **Purpose:** Represent instruction and data memory for the CPU.

  * **Instruction Memory:** `imem.*` – contains the machine code from your C program.
  * **Data Memory:** `dmem.*` – contains initial values for data memory.

* **Usage:**

  * Use `bin_convertor.exe`, `dmem_compile.exe`, or RISC-V tools to generate these from `.elf` files.
  * The CPU reads instructions from `imem` and accesses `dmem` during execution.

---

### 5. **Memory Compilation Tools (`compile.exe`, `dmem_compile.exe`, `Dimem_compile.exe`)**

* **Purpose:** Convert `.elf` or `.o` files into memory files (`.bin`, `.hex`, `.mem`).
* **Usage Example:**

```bash
./Dimem_compile.exe hello.elf imem.mem
./dmem_compile.exe hello.elf dmem.mem
```

These tools allow your CPU simulation to access your C program as memory contents.

---

### 6. **CPU Files (`RISC_v.sv`)**

* **Purpose:** The **top-level SystemVerilog CPU module**. Implements the 5-stage pipeline and hazard detection.
* **Usage:** Used as input for Verilator simulation.

---

### 7. **Testbench (`tb.sv`)**

* **Purpose:** Provides stimulus to the CPU for simulation.
* **Usage:** Compile along with `RISC_v.sv` using Verilator:

```bash
verilator --binary --timing --trace RISC_v.sv tb.sv
```

* Generates the simulation executable (`Vtb`) and waveform file (`riscv.vcd`).

---

### 8. **Waveform Files (`risc.vcd`, `riscw.wcd`)**

* **Purpose:** Capture the CPU’s signal activity during simulation.
* **Usage:** Open with GTKWave:

```bash
gtkwave riscv.vcd
```

This allows you to observe instructions moving through all five pipeline stages, check for hazards, and debug the CPU.

---

### 9. **FPGA Constraints (`riscv.xdc`)**

* **Purpose:** Specifies pin assignments and timing constraints for FPGA implementation.
* **Usage:** Only needed if you want to synthesize the CPU on an FPGA board.

---

### 10. **Installation Executable (`RISCV_Installation.exe`)**

* **Purpose:** Simplifies toolchain setup on Windows/WSL.
* **Usage:** Run this before compiling C programs to generate memory files.

---








