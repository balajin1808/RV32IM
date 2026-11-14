`timescale 1ns / 1ps

module ID_STAGE (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instruction,

    input  logic [4:0]  wb_rd_sel,
    input  logic [31:0] wb_data,
    input  logic        wb_reg_write,

    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,

    output logic [4:0]  rs1,
    output logic [4:0]  rs2,
    output logic [4:0]  rd,
    output logic [31:0] imm_output,

    output logic        branch,
    output logic        mux_inp,
    output logic        memread,
    output logic [1:0]  memtoreg,
    output logic        memwrite,
    output logic        alusrc,
    output logic        reg_write,
    output logic [2:0]  aluop
);

    wire [6:0]  opcode;
    wire [2:0]  fn3;
    wire [11:0] imm;
    wire [19:0] imm_ui;
    wire [12:0] imm_b;
    wire [20:0] imm_j;

    wire [11:0] imm_input_selected;
    wire [19:0] imm_uj_selected;

    decoder D1 (
        .instruction(instruction),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .opcode(opcode),
        .imm11_5(),
        .fn3(fn3),
        .imm(imm),
        .imm_ui(imm_ui),
        .imm_b(imm_b),
        .imm_j(imm_j),
        .fn7_5()
    );

    // The immediate generator adds the final zero bit
    // for branch and JAL offsets by shifting left once.
    assign imm_input_selected =
        (opcode == 7'b1100011) ? imm_b[12:1] : imm;

    assign imm_uj_selected =
        (opcode == 7'b1101111) ? imm_j[20:1] : imm_ui;

    reg_file R1 (
        .clk(clk),
        .reset(reset),
        .rs1_sel(rs1),
        .rs2_sel(rs2),
        .rd_sel(wb_rd_sel),
        .wb_data(wb_data),
        .reg_write(wb_reg_write),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    imm_generator I1 (
        .imm_input(imm_input_selected),
        .imm_output(imm_output),
        .opcode(opcode),
        .imm_input_uj(imm_uj_selected),
        .fn3(fn3)
    );

    Main_Control C1 (
        .opcode(opcode),
        .branch(branch),
        .mux_inp(mux_inp),
        .memread(memread),
        .memtoreg(memtoreg),
        .memwrite(memwrite),
        .alusrc(alusrc),
        .reg_write(reg_write),
        .aluop(aluop)
    );

endmodule