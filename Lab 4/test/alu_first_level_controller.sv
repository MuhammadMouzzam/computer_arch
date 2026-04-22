// Include for MACROS
`include "opcode.vh"


module alu_first_level_controller(
    input  logic [31:0] instr,
    output logic [2:0] ALUOp,
    output logic MemRead,
    output logic MemtoReg,
    output logic MemWrite,
    output logic ALUSrc,
    output logic RegWrite
    );

    always_comb begin

        MemRead = 1'b0;
        MemtoReg = 1'b0;
        MemWrite = 1'b0;
        ALUSrc = 1'b0;
        RegWrite = 1'b0;

        case (instr[6:0])

            // Arithmetic R-Type
            `OPC_ARI_RTYPE : begin 
                ALUOp = 3'b000;
                RegWrite = 1'b1;
                ALUSrc = 1'b0;
                MemRead = 1'b0;
                MemtoReg = 1'b0;
                MemWrite = 1'b0;
            end

            // Arithmetic I-Type
            `OPC_ARI_ITYPE : begin 
                ALUOp = 3'b001;
                RegWrite = 1'b1;
                ALUSrc = 1'b1;
                MemWrite = 1'b0;
                MemRead = 1'b0;
                MemtoReg = 1'b0;
            end

            // LOAD, STORE, JAL, JALR, AUIPC, LUI
            `OPC_LOAD      : begin
                ALUOp = 3'b010;
                RegWrite = 1'b1;
                ALUSrc = 1'b1;
                MemWrite = 1'b0;
                MemRead = 1'b1;
                MemtoReg = 1'b1;
            end

            `OPC_STORE     : ALUOp = 3'b010;
            `OPC_JAL       : ALUOp = 3'b010;
            `OPC_JALR      : ALUOp = 3'b010;
            `OPC_AUIPC     : ALUOp = 3'b010;
            `OPC_LUI       : ALUOp = 3'b010;
            
            // Conditional branches
            `OPC_BRANCH    : ALUOp = 3'b011;

            // Additional reserved for CSR
            `OPC_CSR       : ALUOp = 3'b100;

            // Default safe assignment
            default        : ALUOp = 3'b010;
        endcase
        
    end

endmodule