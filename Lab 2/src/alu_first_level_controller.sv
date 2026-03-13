// Include for MACROS
`include "opcode.vh"


module alu_first_level_controller (input  logic [6:0] opcode, output logic [2:0] ALUOp);

    always_comb begin

        case (opcode)

            // Arithmetic R-Type
            `OPC_ARI_RTYPE : ALUOp = 3'b000;

            // Arithmetic I-Type
            `OPC_ARI_ITYPE : ALUOp = 3'b001;

            // LOAD, STORE, JAL, JALR, AUIPC, LUI
            `OPC_LOAD      : ALUOp = 3'b010; 
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