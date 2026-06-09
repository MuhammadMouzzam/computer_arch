// Include for MACROS
`include "opcode.vh"


module alu_second_level_controller(
    input  logic [2:0] ALUOp,
    input  logic [2:0] func3,
    input  logic [6:0] func7,
    output logic [3:0] alu_operation
    );

    always_comb begin

        // Default safe value
        alu_operation = 4'b0000; // ADD

        case (ALUOp)

            // R-type arithmetic instructions:
            // add, sub, sll, slt, sltu, xor, srl, sra, or, and
            3'b000: begin

                case (func3)

                    // ADD / SUB
                    `FNC_ADD_SUB: begin

                        if (func7 == `FNC7_0) begin
                            alu_operation = 4'b0000; // ADD
                        end

                        else if (func7 == `FNC7_1) begin
                            alu_operation = 4'b1111; // SUB
                        end

                        else begin
                            alu_operation = 4'b0000; // Safe default for invalid func7
                        end

                    end


                    // SLL
                    `FNC_SLL: begin

                        if (func7 == `FNC7_0) begin
                            alu_operation = 4'b0101; // SLL
                        end

                        else begin
                            alu_operation = 4'b0000; // Safe default for invalid func7
                        end

                    end


                    // SLT
                    `FNC_SLT: begin

                        if (func7 == `FNC7_0) begin
                            alu_operation = 4'b0100; // SLT
                        end

                        else begin
                            alu_operation = 4'b0000; // Safe default for invalid func7
                        end

                    end


                    // SLTU
                    `FNC_SLTU: begin

                        if (func7 == `FNC7_0) begin
                            alu_operation = 4'b0110; // SLTU
                        end

                        else begin
                            alu_operation = 4'b0000; // Safe default for invalid func7
                        end

                    end


                    // XOR
                    `FNC_XOR: begin

                        if (func7 == `FNC7_0) begin
                            alu_operation = 4'b0001; // XOR
                        end

                        else begin
                            alu_operation = 4'b0000; // Safe default for invalid func7
                        end

                    end


                    // SRL / SRA
                    `FNC_SRL_SRA: begin

                        if (func7 == `FNC7_0) begin
                            alu_operation = 4'b0111; // SRL
                        end

                        else if (func7 == `FNC7_1) begin
                            alu_operation = 4'b1000; // SRA
                        end

                        else begin
                            alu_operation = 4'b0000; // Safe default for invalid func7
                        end

                    end


                    // OR
                    `FNC_OR: begin

                        if (func7 == `FNC7_0) begin
                            alu_operation = 4'b0010; // OR
                        end

                        else begin
                            alu_operation = 4'b0000; // Safe default for invalid func7
                        end

                    end


                    // AND
                    `FNC_AND: begin

                        if (func7 == `FNC7_0) begin
                            alu_operation = 4'b0011; // AND
                        end

                        else begin
                            alu_operation = 4'b0000; // Safe default for invalid func7
                        end

                    end


                    // Safe default for invalid func3
                    default: begin
                        alu_operation = 4'b0000; // ADD
                    end

                endcase

            end


            // I-type arithmetic instructions:
            // addi, slli, slti, sltiu, xori, srli, srai, ori, andi
            3'b001: begin

                case (func3)

                    // ADDI
                    `FNC_ADD_SUB: begin
                        alu_operation = 4'b0000; // ADDI
                    end


                    // SLLI
                    `FNC_SLL: begin

                        if (func7 == `FNC7_0) begin
                            alu_operation = 4'b0101; // SLLI
                        end

                        else begin
                            alu_operation = 4'b0000; // Safe default for invalid immediate[31:25]
                        end

                    end


                    // SLTI
                    `FNC_SLT: begin
                        alu_operation = 4'b0100; // SLTI
                    end


                    // SLTIU
                    `FNC_SLTU: begin
                        alu_operation = 4'b0110; // SLTIU
                    end


                    // XORI
                    `FNC_XOR: begin
                        alu_operation = 4'b0001; // XORI
                    end


                    // SRLI / SRAI
                    `FNC_SRL_SRA: begin

                        if (func7 == `FNC7_0) begin
                            alu_operation = 4'b0111; // SRLI
                        end

                        else if (func7 == `FNC7_1) begin
                            alu_operation = 4'b1000; // SRAI
                        end

                        else begin
                            alu_operation = 4'b0000; // Safe default for invalid immediate[31:25]
                        end

                    end


                    // ORI
                    `FNC_OR: begin
                        alu_operation = 4'b0010; // ORI
                    end


                    // ANDI
                    `FNC_AND: begin
                        alu_operation = 4'b0011; // ANDI
                    end


                    // Safe default for invalid func3
                    default: begin
                        alu_operation = 4'b0000; // ADD
                    end

                endcase

            end


            // ADD-only class:
            3'b010: begin
                alu_operation = 4'b0000; // ADD
            end

            // lui:
            3'b011: begin
                alu_operation = 4'b1001; // PASS_B
            end

            // Safe default
            default: begin
                alu_operation = 4'b0000; // ADD
            end

        endcase

    end

endmodule