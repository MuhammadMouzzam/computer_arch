// Include for MACROS
`include "opcode.vh"


module alu_first_level_controller(
    input  logic [31:0] instr,

    output logic        RegWrite,
    output logic        ALUSRC_1,
    output logic        ALUSRC_2,
    output logic [2:0]  ALUOp,

    output logic [2:0]  br_type,
    output logic        br_en,

    output logic        MemWrite,
    output logic        MemRead,

    output logic [1:0]  wb_sel
    );

    // ALUOp encoding
    localparam logic [2:0] ALUOP_RTYPE  = 3'b000;
    localparam logic [2:0] ALUOP_ITYPE  = 3'b001;
    localparam logic [2:0] ALUOP_ADD    = 3'b010;
    localparam logic [2:0] ALUOP_PASS_B = 3'b011;

    // Writeback mux encoding
    localparam logic [1:0] WB_ALU = 2'b00;
    localparam logic [1:0] WB_MEM = 2'b01;
    localparam logic [1:0] WB_PC4 = 2'b10;

    // Custom branch type for unconditional JAL.
    localparam logic [2:0] BR_JAL = 3'b010;

    logic [6:0] opcode;

    assign opcode = instr[6:0];


    always_comb begin

        // Default safe values
        RegWrite = 1'b0;
        ALUSRC_1 = 1'b0;
        ALUSRC_2 = 1'b0;
        ALUOp    = ALUOP_ADD;

        br_type  = 3'b000;
        br_en    = 1'b0;

        MemWrite = 1'b0;
        MemRead  = 1'b0;

        wb_sel   = WB_ALU;


        case (opcode)

            // R-Type:
            // add, sub, sll, slt, sltu, xor, srl, sra, or, and
            `OPC_ARI_RTYPE: begin

                RegWrite = 1'b1;
                ALUSRC_1 = 1'b0;        // operand1 = rs1
                ALUSRC_2 = 1'b0;        // operand2 = rs2
                ALUOp    = ALUOP_RTYPE;

                wb_sel   = WB_ALU;      // rd = ALU result

            end


            // I-Type Arithmetic:
            // addi, slli, slti, sltiu, xori, srli, srai, ori, andi
            `OPC_ARI_ITYPE: begin

                RegWrite = 1'b1;
                ALUSRC_1 = 1'b0;        // operand1 = rs1
                ALUSRC_2 = 1'b1;        // operand2 = immediate
                ALUOp    = ALUOP_ITYPE;

                wb_sel   = WB_ALU;      // rd = ALU result

            end


            // Load:
            // lb, lh, lw, lbu, lhu
            `OPC_LOAD: begin

                RegWrite = 1'b1;
                ALUSRC_1 = 1'b0;        // operand1 = rs1 base address
                ALUSRC_2 = 1'b1;        // operand2 = immediate offset
                ALUOp    = ALUOP_ADD;   // address = rs1 + immediate

                MemRead  = 1'b1;
                MemWrite = 1'b0;

                wb_sel   = WB_MEM;      // rd = memory data

            end


            // Store:
            // sw
            `OPC_STORE: begin

                RegWrite = 1'b0;
                ALUSRC_1 = 1'b0;        // operand1 = rs1 base address
                ALUSRC_2 = 1'b1;        // operand2 = immediate offset
                ALUOp    = ALUOP_ADD;   // address = rs1 + immediate

                MemRead  = 1'b0;
                MemWrite = 1'b1;

                wb_sel   = WB_ALU;      // don't care, safe default

            end


            // U-Type:
            // lui
            `OPC_LUI: begin

                RegWrite = 1'b1;
                ALUSRC_1 = 1'b0;        // operand1 unused for PASS_B
                ALUSRC_2 = 1'b1;        // operand2 = U-type immediate
                ALUOp    = ALUOP_PASS_B;

                wb_sel   = WB_ALU;      // rd = immediate

            end


            // J-Type:
            // jal
            `OPC_JAL: begin

                RegWrite = 1'b1;
                ALUSRC_1 = 1'b1;        // operand1 = PC
                ALUSRC_2 = 1'b1;        // operand2 = J-type immediate
                ALUOp    = ALUOP_ADD;   // target = PC + immediate

                br_en    = 1'b1;
                br_type  = BR_JAL;      // unconditional jump

                wb_sel   = WB_PC4;      // rd = PC + 4

            end


            // B-Type:
            // beq and bne
            `OPC_BRANCH: begin

                RegWrite = 1'b0;
                ALUSRC_1 = 1'b1;        // operand1 = PC
                ALUSRC_2 = 1'b1;        // operand2 = B-type immediate
                ALUOp    = ALUOP_ADD;   // target = PC + immediate

                br_en    = 1'b1;
                br_type  = instr[14:12]; // BEQ or BNE sent to branch_unit

                wb_sel   = WB_ALU;      // don't care, safe default

            end


            // Unsupported instruction -> NOP
            default: begin

                RegWrite = 1'b0;
                ALUSRC_1 = 1'b0;
                ALUSRC_2 = 1'b0;
                ALUOp    = ALUOP_ADD;

                br_type  = 3'b000;
                br_en    = 1'b0;

                MemWrite = 1'b0;
                MemRead  = 1'b0;

                wb_sel   = WB_ALU;

            end

        endcase

    end

endmodule