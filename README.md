# RISC-V M Extension (RV32IM)

Starter repo for your single-cycle RV32I core extended with the M extension (multiply and divide) (Groups 1 to 4). One member creates the group's repo with **Use this template** → **Create a new repository** (public), and adds the others as collaborators.

Copy your single-cycle core into this repo and add the M instructions; the ports are the same as your single-cycle core's.

Spec: [Single_Cycle_RISCV_M/](Single_Cycle_RISCV_M/)

## Submit

1. Install the **`risc-n-roll-ci`** GitHub App on your group's repo (that exact repo, or CI never sees it).
2. Write your design, commit and push. `rnr-stage.yaml` suggests `Single_Cycle_RISCV_M/rtl.sv`; if you use other file names, edit the paths there (no spaces in paths).
3. Submit your repo link (one per group) through the course form.

CI checks each push on its next run, which can take a few hours. Its synthesizer (Yosys 0.33) cannot parse assignment patterns like `'{default: 0}`; use a `for` loop instead.
