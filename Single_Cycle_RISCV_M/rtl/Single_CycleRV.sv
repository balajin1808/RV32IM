`timescale 1ns / 1ps

module Single_CycleRV (
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
    input  logic [31:0] instruction,
    input  logic [31:0] mem_out,

    output logic [31:0] rs2_data,
    output logic [31:0] alu_out,
    output logic [31:0] address,
    output logic        mem_write,
    output logic        mem_read,
    output logic [2:0]  fn3,
    output logic [6:0]  opcode
);

    wire [31:0] rs1_data;
    wire [31:0] imm_out;
    wire [31:0] pc_target;
    wire [31:0] pc_plus_imm;
    wire [31:0] return_addr;
    wire [31:0] wb_data;

    wire [4:0] rd_sel;
    wire [2:0] aluop;
    wire [1:0] memtoreg;

    wire and_out_ex;
    wire branch;
    wire alu_src;
    wire fn7_5;
    wire mux_inp;
    wire reg_write;

    assign opcode = instruction[6:0];
    assign fn3 = instruction[14:12];
    assign fn7_5 = instruction[30];

    // AUIPC writeback needs PC + immediate.
    assign pc_plus_imm = address + imm_out;

    if_stage if_st (
        .clk(clk),
        .reset(reset),
        .stall(1'b0),
        .and_out(and_out_ex),
        .pc_next(),
        .pc_signed_offset(pc_target),
        .address(address),
        .pc_new(return_addr)
    );

    ID_STAGE id_st (
        .clk(clk),
        .reset(reset),
        .instruction(instruction),

        .wb_rd_sel(rd_sel),
        .wb_data(wb_data),
        .wb_reg_write(reg_write),

        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .rs1(),
        .rs2(),
        .rd(rd_sel),
        .imm_output(imm_out),

        .branch(branch),
        .mux_inp(mux_inp),
        .memread(mem_read),
        .memtoreg(memtoreg),
        .memwrite(mem_write),
        .alusrc(alu_src),
        .reg_write(reg_write),
        .aluop(aluop)
    );

            EX_Stage ex_st (
        .pc(address),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .imm_output(imm_out),
        .opcode(opcode),
        .funct7(instruction[31:25]),
        .aluop(aluop),
        .fn3(fn3),
        .fn7_5(fn7_5),
        .branch(branch),
        .alusrc(alu_src),

        .alu_result(alu_out),
        .zero(),
        .and_out(and_out_ex),
        .pc_target(pc_target)
    );
    WB_Stage wb_st (
        .mem_out(mem_out),
        .alu_out(alu_out),
        .memtoreg(memtoreg),
        .wb_data(wb_data),
        .return_addr(return_addr),
        .imm_out(imm_out),
        .pc_signed_offset(pc_plus_imm),
        .opcode_out_d(opcode)
    );

endmodule