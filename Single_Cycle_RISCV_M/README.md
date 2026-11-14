# RISC-V M Extension (RV32IM)

One module, `single_cycle_riscv_m`: your single-cycle RV32I core extended with the **M extension** (RV32IM + Zicsr in the
course's wording). It keeps the port set of your single-cycle core, so you can extend what you already have. CI checks the
behaviour with a trusted harness that plays instruction memory and data memory.

### Module Specification

```SystemVerilog
module single_cycle_riscv_m (
    input  logic        clk,
    input  logic        reset,          // asynchronous, active high
    input  logic        stall,          // driven 0 by CI
    input  logic [31:0] instruction,
    input  logic [31:0] mem_out,
    output logic [31:0] rs2_data,
    output logic [31:0] alu_out,
    output logic        mem_write,
    output logic        mem_read,
    output logic [2:0]  fn3,
    output logic [6:0]  opcode,
    output logic [31:0] address
);
```

### Ports (names, widths and directions are fixed)

| Port | Dir | Width | Meaning |
|---|---|---|---|
| `clk` | in | 1 | clock, rising edge |
| `reset` | in | 1 | asynchronous, active high; PC becomes `32'h8000_0000`, registers become 0 |
| `stall` | in | 1 | driven 0 by this CI; keep the port |
| `instruction` | in | 32 | instruction at `address`, **combinational** read |
| `mem_out` | in | 32 | load data for `alu_out` / `fn3`, **combinational**, already extended |
| `rs2_data` | out | 32 | store data (full `rs2` value) |
| `alu_out` | out | 32 | ALU result / data memory address |
| `mem_write` | out | 1 | a store is executing |
| `mem_read` | out | 1 | a load is executing |
| `fn3` | out | 3 | funct3 of the load/store |
| `opcode` | out | 7 | opcode of the executing instruction (not observed by CI, keep the port) |
| `address` | out | 32 | PC of the instruction being fetched |

Memory model: instruction memory 512 words (bits `[10:2]` of `address`), data memory 256 words (bits `[9:2]` of `alu_out`),
zero-initialised, written on the clock edge when `mem_write` is high. Program loaded at `0x8000_0000`.

### RV32M (funct7 = 0000001, opcode 0110011)

| funct3 | Instruction | Result |
|---|---|---|
| 000 | MUL | low 32 bits of rs1 * rs2 |
| 001 | MULH | high 32 bits, signed * signed |
| 010 | MULHSU | high 32 bits, signed rs1 * unsigned rs2 |
| 011 | MULHU | high 32 bits, unsigned * unsigned |
| 100 | DIV | signed division, rounded toward zero |
| 101 | DIVU | unsigned division |
| 110 | REM | signed remainder, sign follows the dividend |
| 111 | REMU | unsigned remainder |

Special cases (no exceptions are raised): `x / 0` = all ones (`DIV`, `DIVU`), `x % 0` = `x` (`REM`, `REMU`); signed overflow
`-2^31 / -1` = `-2^31` and `-2^31 % -1` = `0`. Everything else is RV32I, unchanged.

### What the CI checks

CI runs three programs (special operand pairs, a pseudo-random loop, and a dense random mix) and compares the sequence of committed stores against a trusted reference. A multi-cycle multiplier/divider is fine; a design may take about ten cycles per instruction on average.

> [!IMPORTANT]
> Your module and port names are up to you, but the port count, directions, widths and behavior must match this spec. If your names differ, map them in `rnr-stage.yaml`.
