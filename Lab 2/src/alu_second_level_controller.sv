// Include for MACROS
`include "opcode.vh"

module alu_second_level_controller (input  logic [2:0] ALUOp, input  logic [2:0] func3, input  logic [6:0] func7, output logic [3:0] alu_operation);

    always_comb begin

        case (ALUOp)

            // R-type arithmetic instructions
            3'b000: begin

                // Check which R-type arithmetic instruction through func3
                case (func3)

                    // ADD and SUB instruction
                    `FNC_ADD_SUB: begin

                        // Check func7 to differentiate between ADD and SUB
                        if (func7 == `FNC7_1)

                            alu_operation = 4'b1111; // SUB

                        else

                            alu_operation = 4'b0000; // ADD

                    end

                    // SRL and SRA instruction
                    `FNC_SRL_SRA: begin

                        // Check func7 to differentiate between SRL and SRA
                        if (func7 == `FNC7_1)

                            alu_operation = 4'b1000; // SRA

                        else

                            alu_operation = 4'b0111; // SRL

                    end

                    // Remaining R-Type arithmetic instructions
                    `FNC_XOR    : alu_operation = 4'b0001; // XOR
                    `FNC_OR     : alu_operation = 4'b0010; // OR
                    `FNC_AND    : alu_operation = 4'b0011; // AND
                    `FNC_SLT    : alu_operation = 4'b0100; // SLT
                    `FNC_SLL    : alu_operation = 4'b0101; // SLL
                    `FNC_SLTU   : alu_operation = 4'b0110; // SLTU

                    // Safe ADD alu_operation as default
                    default     : alu_operation = 4'b0000;

                endcase

            end

            // I-type arithmetic instructions
            3'b001: begin

                // Check which I-type arithmetic instruction through func3
                case (func3)

                    // SRLI and SRAI instruction
                    `FNC_SRL_SRA: begin

                        // Check func7 to differentiate between SRLI and SRAI
                        if (func7 == `FNC7_1)

                            alu_operation = 4'b1000; // SRAI

                        else

                            alu_operation = 4'b0111; // SRLI

                    end
                
                    // Remaining I-Type arithmetic instructions
                    `FNC_ADD_SUB: alu_operation = 4'b0000; // ADDI
                    `FNC_XOR    : alu_operation = 4'b0001; // XORI
                    `FNC_OR     : alu_operation = 4'b0010; // ORI
                    `FNC_AND    : alu_operation = 4'b0011; // ANDI
                    `FNC_SLT    : alu_operation = 4'b0100; // SLTI
                    `FNC_SLL    : alu_operation = 4'b0101; // SLLI
                    `FNC_SLTU   : alu_operation = 4'b0110; // SLTIU


                    // Safe ADD alu_operation as default
                    default     : alu_operation = 4'b0000;

                endcase

            end

            // ADD only class:
            // load/store/jal/jalr/auipc/lui
            3'b010: begin

                alu_operation = 4'b0000; // ADD

            end

            // Branch instructions
            3'b011: begin

                // Check which conditional branch instruction through func3
                case (func3)

                    `FNC_BEQ  : alu_operation = 4'b1111; // SUB
                    `FNC_BNE  : alu_operation = 4'b1111; // SUB
                    `FNC_BLT  : alu_operation = 4'b0100; // SLT
                    `FNC_BGE  : alu_operation = 4'b0100; // SLT
                    `FNC_BLTU : alu_operation = 4'b0110; // SLTU
                    `FNC_BGEU : alu_operation = 4'b0110; // SLTU

                    // Safe ADD alu_operation as default
                    default   : alu_operation = 4'b0000;

                endcase

            end

            // Safe ADD alu_operation as default
            default: begin

                alu_operation = 4'b0000;

            end

        endcase
        
    end

endmodule