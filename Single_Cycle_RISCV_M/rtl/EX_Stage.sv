`timescale 1ns / 1ps

module EX_Stage (
    input  logic [31:0] pc,
    input  logic [31:0] rs1_data,
    input  logic [31:0] rs2_data,
    input  logic [31:0] imm_output,
    input  logic [6:0]  opcode,
    input  logic [6:0]  funct7,
    input  logic [2:0]  aluop,
    input  logic [2:0]  fn3,
    input  logic        fn7_5,
    input  logic        branch,
    input  logic        alusrc,

    output logic [31:0] alu_result,
    output logic        zero,
    output logic        and_out,
    output logic [31:0] pc_target
);

    wire [31:0] alu_b;
    wire [3:0]  alu_control;
    wire [31:0] base_result;
    wire [31:0] m_result;
    wire        m_enable;

    logic branch_taken;

    // Existing RV32I ALU control.
    ALU_Ctrl ac (
        .aluop(aluop),
        .fn3(fn3),
        .fn7_5(fn7_5),
        .alu_control(alu_control)
    );

    MUX21 mux_ex (
        .a(rs2_data),
        .b(imm_output),
        .sel(alusrc),
        .y(alu_b)
    );

    // Existing RV32I ALU.
    ALU alu1 (
        .A(rs1_data),
        .B(alu_b),
        .ALU_Control(alu_control),
        .Result(base_result),
        .Zero()
    );

    // Detect RV32M instructions.
    rv32m_control m_ctrl (
        .opcode(opcode),
        .funct7(funct7),
        .m_enable(m_enable)
    );

    // RV32M always operates on two register operands.
    rv32m_alu m_alu (
        .enable(m_enable),
        .funct3(fn3),
        .operand_a(rs1_data),
        .operand_b(rs2_data),
        .result(m_result)
    );

    // Select the result sent to writeback.
    assign alu_result = m_enable ? m_result : base_result;
    assign zero = (alu_result == 32'd0);

    // Branch comparisons.
    always_comb begin
        branch_taken = 1'b0;

        if (branch) begin
            case (fn3)
                3'b000: branch_taken = (rs1_data == rs2_data);
                3'b001: branch_taken = (rs1_data != rs2_data);

                3'b100: branch_taken =
                    ($signed(rs1_data) < $signed(rs2_data));

                3'b101: branch_taken =
                    ($signed(rs1_data) >= $signed(rs2_data));

                3'b110: branch_taken = (rs1_data < rs2_data);
                3'b111: branch_taken = (rs1_data >= rs2_data);

                default: branch_taken = 1'b0;
            endcase
        end
    end

    // Branch and jump redirection.
    always_comb begin
        and_out = 1'b0;
        pc_target = pc + 32'd4;

        if (opcode == 7'b1101111) begin
            and_out = 1'b1;
            pc_target = pc + imm_output;
        end
        else if ((opcode == 7'b1100111) &&
                 (fn3 == 3'b000)) begin
            and_out = 1'b1;
            pc_target = (rs1_data + imm_output) & 32'hfffffffe;
        end
        else if (branch_taken) begin
            and_out = 1'b1;
            pc_target = pc + imm_output;
        end
    end

endmodule