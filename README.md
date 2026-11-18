# Single-Cycle RV32IM Processor

A modular SystemVerilog implementation of a 32-bit RISC-V processor supporting the **RV32I** base integer instruction set and the **RV32M** multiplication and division extension, developed as part of the **Computer Organization and Design (COD)** course project at **PES University** (Group 4).

## Project Overview

The processor implements:
- RV32I integer arithmetic and logical operations
- Immediate arithmetic and logical operations
- Conditional branches and jumps
- Load and store instructions
- RV32M multiplication, division, and remainder operations
- 32x32 register-file access and writeback (`x0` hardwired to zero)
- External instruction and data memory interfaces for course CI evaluation

## Architecture

    External Instruction Memory
               |
               v
       Instruction Fetch (if_stage)
               |
               v
       Instruction Decode & Register Bank (ID_STAGE)
               |
               v
         Execution Unit (EX_Stage)
           /        \
          v          v
       ALU        rv32m_alu
           \        /
            v      v
           EX Result
               |
               v
       External Data Memory
               |
               v
         Writeback (WB_Stage)
               |
               v
         Register Bank

## RV32I Instruction Support

| Category | Instructions |
| :--- | :--- |
| Arithmetic | `ADD`, `SUB` |
| Logical | `AND`, `OR`, `XOR` |
| Shifts | `SLL`, `SRL`, `SRA` |
| Comparisons | `SLT`, `SLTU` |
| Immediate operations | `ADDI`, `ANDI`, `ORI`, `XORI`, `SLTI`, `SLTIU`, `SLLI`, `SRLI`, `SRAI` |
| Branches | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` |
| Jumps | `JAL`, `JALR` |
| Upper immediate | `LUI`, `AUIPC` |
| Loads | `LB`, `LH`, `LW`, `LBU`, `LHU` |
| Stores | `SB`, `SH`, `SW` |

## RV32M Extension

RV32M instructions share R-type `opcode` `0110011` and are distinguished by `funct7 = 0000001`.

| `funct3` | Instruction | Operation |
| :--- | :--- | :--- |
| `000` | `MUL` | Lower 32 bits of product |
| `001` | `MULH` | Upper 32 bits, signed x signed |
| `010` | `MULHSU` | Upper 32 bits, signed x unsigned |
| `011` | `MULHU` | Upper 32 bits, unsigned x unsigned |
| `100` | `DIV` | Signed division, rounded toward zero |
| `101` | `DIVU` | Unsigned division |
| `110` | `REM` | Signed remainder |
| `111` | `REMU` | Unsigned remainder |

### Division Corner Cases
- Division by zero (`rs2 == 0`) returns `0xFFFFFFFF` (`DIV`, `DIVU`).
- Remainder by zero (`rs2 == 0`) returns the dividend `rs1` (`REM`, `REMU`).
- Signed overflow (`INT_MIN / -1`, i.e., `0x80000000 / 0xFFFFFFFF`) returns `INT_MIN` (`0x80000000`) for `DIV` and `0` for `REM`.

## Course Evaluation Interface

- **Top-level module:** `Single_CycleRV` (mapped via `top_module: Single_CycleRV` in `rnr-stage.yaml`)

| Port | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `clk` | Input | 1 | Rising-edge clock |
| `reset` | Input | 1 | Asynchronous active-high reset |
| `stall` | Input | 1 | Stall input; driven low by course CI |
| `instruction` | Input | 32 | Instruction supplied for the current `address` |
| `mem_out` | Input | 32 | Already-extended load data |
| `rs2_data` | Output | 32 | Second source-register value (store data) |
| `alu_out` | Output | 32 | ALU/M-ALU result and data-memory address |
| `mem_write` | Output | 1 | Store control |
| `mem_read` | Output | 1 | Load control |
| `fn3` | Output | 3 | Load/store `funct3` |
| `opcode` | Output | 7 | Opcode of executing instruction |
| `address` | Output | 32 | PC of instruction being fetched |

### Reset Behaviour
On active-high `reset`:
- Program counter resets to `0x80000000`.
- General-purpose registers are cleared (`x0` remains `0`).

## Repository Structure

    RV32IM/
    ├── Single_Cycle_RISCV_M/
    │   ├── README.md
    │   └── rtl/                    # 18 modular SystemVerilog RTL files
    │       ├── Single_CycleRV.sv
    │       ├── if_stage.sv / IF_Adder.sv
    │       ├── ID_STAGE.sv / decoder.sv / imm_generator.sv / reg_file.sv / Main_Control.sv / control_gen.sv
    │       ├── EX_Stage.sv / ALU.sv / ALU_Ctrl.sv / rv32m_control.sv / rv32m_alu.sv / And_Gate.sv / MUX21.sv / mux31.sv
    │       └── WB_Stage.sv
    ├── compliance_test/
    │   ├── sim_main.cpp            # Verilator ELF loader, memory model, and signature dumper
    │   ├── run_tests.sh            # Compliance runner & Sail signature diff script
    │   └── compliance_results.txt  # 47/47 passing test summary
    ├── rnr-stage.yaml              # Course CI configuration (stage: single_cycle_riscv_m)
    └── README.md

## Verification

### 1. Course RISC-n-Roll CI
Configured via `rnr-stage.yaml` (`stage: single_cycle_riscv_m`, `top_module: Single_CycleRV`). Checks configuration paths, Yosys synthesis, port/lint validation, and committed store sequences against the course reference.

### 2. RISC-V Architectural Compliance (`compliance_test/`)
Verified independently in WSL/Ubuntu using **RISC-V Architectural Certification Tests (`riscv-arch-test` `act4`)**, **Sail (`sail_riscv_sim 0.16`)**, **Verilator**, and **RISC-V GCC (`riscv-none-elf-gcc`)**:
- **47 / 47 tests passed (`0` failed)**:
  - **39 RV32I** tests
  - **8 RV32M** tests (`mul`, `mulh`, `mulhsu`, `mulhu`, `div`, `divu`, `rem`, `remu`)

### 3. Vivado Simulation & RTL Analysis
Verified functional waveforms, elaborated schematic, and RTL linter checks in AMD Vivado.

## Scope & Limitations
- Covers **RV32I + RV32M** unprivileged integer instructions.
- Does not implement CSRs, traps, or privileged-mode instructions.

## Contributors (Group 4)
- **B Supriya** (`PES2UG24EC020`)
- **Balaji N** (`PES2UG24EC021`)
- **Bhoomika H M** (`PES2UG24EC023`)

## References
- RISC-V Unprivileged ISA Specification
- [riscv-arch-test (ACT4)](https://github.com/riscv/riscv-arch-test)
- [Sail RISC-V Model](https://github.com/riscv/sail-riscv)
- Verilator Documentation
