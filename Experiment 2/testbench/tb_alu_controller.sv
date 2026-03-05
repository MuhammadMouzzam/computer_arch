`timescale 1ns/1ps

// Include for MACROS
`include "opcode.vh"

module tb_alu_controller;

    // DUT signals
    logic [6:0] opcode;
    logic [2:0] func3;
    logic [6:0] func7;

    logic [2:0] ALUOp;
    logic [3:0] alu_operation;

    // Expected outputs
    logic [2:0] expected_ALUOp;
    logic [3:0] expected_alu_operation;

    // DUT instances
    alu_first_level_controller first_level_inst (
        .opcode(opcode),
        .ALUOp(ALUOp)
    );

    alu_second_level_controller second_level_inst (
        .ALUOp(ALUOp),
        .func3(func3),
        .func7(func7),
        .alu_operation(alu_operation)
    );

    // ALU operation encodings
    localparam logic [3:0] ALU_ADD  = 4'b0000;
    localparam logic [3:0] ALU_XOR  = 4'b0001;
    localparam logic [3:0] ALU_OR   = 4'b0010;
    localparam logic [3:0] ALU_AND  = 4'b0011;
    localparam logic [3:0] ALU_SLT  = 4'b0100;
    localparam logic [3:0] ALU_SLL  = 4'b0101;
    localparam logic [3:0] ALU_SLTU = 4'b0110;
    localparam logic [3:0] ALU_SRL  = 4'b0111;
    localparam logic [3:0] ALU_SRA  = 4'b1000;
    localparam logic [3:0] ALU_SUB  = 4'b1111;

    // Test results
    int total_tests  = 0;
    int passed_tests = 0;
    int failed_tests = 0;

    // Reference model for first-level controller
    function automatic logic [2:0] expected_first_level(
        input logic [6:0] op
    );
        case (op)
            `OPC_ARI_RTYPE : expected_first_level = 3'b000;
            `OPC_ARI_ITYPE : expected_first_level = 3'b001;

            `OPC_LOAD,
            `OPC_STORE,
            `OPC_JAL,
            `OPC_JALR,
            `OPC_AUIPC,
            `OPC_LUI       : expected_first_level = 3'b010;

            `OPC_BRANCH    : expected_first_level = 3'b011;
            `OPC_CSR       : expected_first_level = 3'b100;

            default        : expected_first_level = 3'b010;
        endcase
    endfunction

    // Reference model for second-level controller
    function automatic logic [3:0] expected_second_level(
        input logic [2:0] op_group,
        input logic [2:0] f3,
        input logic [6:0] f7
    );
        begin
            case (op_group)

                // R-type arithmetic instructions
                3'b000: begin
                    case (f3)
                        `FNC_ADD_SUB: begin
                            if (f7 == `FNC7_1)
                                expected_second_level = ALU_SUB;
                            else
                                expected_second_level = ALU_ADD;
                        end

                        `FNC_SRL_SRA: begin
                            if (f7 == `FNC7_1)
                                expected_second_level = ALU_SRA;
                            else
                                expected_second_level = ALU_SRL;
                        end

                        `FNC_XOR  : expected_second_level = ALU_XOR;
                        `FNC_OR   : expected_second_level = ALU_OR;
                        `FNC_AND  : expected_second_level = ALU_AND;
                        `FNC_SLT  : expected_second_level = ALU_SLT;
                        `FNC_SLL  : expected_second_level = ALU_SLL;
                        `FNC_SLTU : expected_second_level = ALU_SLTU;

                        default   : expected_second_level = ALU_ADD;
                    endcase
                end

                // I-type arithmetic instructions
                3'b001: begin
                    case (f3)
                        `FNC_SRL_SRA: begin
                            if (f7 == `FNC7_1)
                                expected_second_level = ALU_SRA;
                            else
                                expected_second_level = ALU_SRL;
                        end

                        `FNC_ADD_SUB: expected_second_level = ALU_ADD;
                        `FNC_XOR    : expected_second_level = ALU_XOR;
                        `FNC_OR     : expected_second_level = ALU_OR;
                        `FNC_AND    : expected_second_level = ALU_AND;
                        `FNC_SLT    : expected_second_level = ALU_SLT;
                        `FNC_SLL    : expected_second_level = ALU_SLL;
                        `FNC_SLTU   : expected_second_level = ALU_SLTU;

                        default     : expected_second_level = ALU_ADD;
                    endcase
                end

                // ADD-only class
                3'b010: expected_second_level = ALU_ADD;

                // Branch instructions
                3'b011: begin
                    case (f3)
                        `FNC_BEQ  : expected_second_level = ALU_SUB;
                        `FNC_BNE  : expected_second_level = ALU_SUB;
                        `FNC_BLT  : expected_second_level = ALU_SLT;
                        `FNC_BGE  : expected_second_level = ALU_SLT;
                        `FNC_BLTU : expected_second_level = ALU_SLTU;
                        `FNC_BGEU : expected_second_level = ALU_SLTU;
                        default   : expected_second_level = ALU_ADD;
                    endcase
                end

                // CSR / reserved
                3'b100: expected_second_level = ALU_ADD;

                default: expected_second_level = ALU_ADD;
            endcase
        end
    endfunction

    // Helper function to print ALUOp group name
    function automatic string aluop_name(input logic [2:0] op_group);
        case (op_group)
            3'b000: aluop_name = "R_TYPE";
            3'b001: aluop_name = "I_TYPE";
            3'b010: aluop_name = "ADD_CLASS";
            3'b011: aluop_name = "BRANCH";
            3'b100: aluop_name = "CSR";
            default: aluop_name = "UNKNOWN";
        endcase
    endfunction

    // Helper function to print alu_operation name
    function automatic string alu_operation_name(input logic [3:0] op);
        case (op)
            ALU_ADD  : alu_operation_name = "ADD";
            ALU_SUB  : alu_operation_name = "SUB";
            ALU_XOR  : alu_operation_name = "XOR";
            ALU_OR   : alu_operation_name = "OR";
            ALU_AND  : alu_operation_name = "AND";
            ALU_SLT  : alu_operation_name = "SLT";
            ALU_SLL  : alu_operation_name = "SLL";
            ALU_SLTU : alu_operation_name = "SLTU";
            ALU_SRL  : alu_operation_name = "SRL";
            ALU_SRA  : alu_operation_name = "SRA";
            default  : alu_operation_name = "UNKNOWN";
        endcase
    endfunction

    // Task to run a single test
    task automatic run_test(
        input logic [6:0] op,
        input logic [2:0] f3,
        input logic [6:0] f7
    );
        begin
            opcode = op;
            func3  = f3;
            func7  = f7;

            #1;

            expected_ALUOp         = expected_first_level(op);
            expected_alu_operation = expected_second_level(expected_ALUOp, f3, f7);

            total_tests++;

            if ((ALUOp !== expected_ALUOp) || (alu_operation !== expected_alu_operation)) begin
                failed_tests++;
                $display("FAIL | opcode=%b | func3=%b | func7=%b | ALUOp=%b (%s) | expected_ALUOp=%b (%s) | alu_operation=%b (%s) | expected_alu_operation=%b (%s)",
                         op, f3, f7,
                         ALUOp, aluop_name(ALUOp),
                         expected_ALUOp, aluop_name(expected_ALUOp),
                         alu_operation, alu_operation_name(alu_operation),
                         expected_alu_operation, alu_operation_name(expected_alu_operation));
            end
            else begin
                passed_tests++;
            end
        end
    endtask

    // Begin testing
    initial begin
        $display("Testing First Level and Second Level Controllers");

        // Initialize inputs
        opcode = 7'b0;
        func3  = 3'b0;
        func7  = 7'b0;
        #5;

        // =========================================
        // Directed tests
        // =========================================

        // R-type arithmetic
        run_test(`OPC_ARI_RTYPE, `FNC_ADD_SUB, 7'b0000000); // ADD
        run_test(`OPC_ARI_RTYPE, `FNC_ADD_SUB, 7'b0100000); // SUB
        run_test(`OPC_ARI_RTYPE, `FNC_XOR,     7'b0000000); // XOR
        run_test(`OPC_ARI_RTYPE, `FNC_OR,      7'b0000000); // OR
        run_test(`OPC_ARI_RTYPE, `FNC_AND,     7'b0000000); // AND
        run_test(`OPC_ARI_RTYPE, `FNC_SLT,     7'b0000000); // SLT
        run_test(`OPC_ARI_RTYPE, `FNC_SLL,     7'b0000000); // SLL
        run_test(`OPC_ARI_RTYPE, `FNC_SLTU,    7'b0000000); // SLTU
        run_test(`OPC_ARI_RTYPE, `FNC_SRL_SRA, 7'b0000000); // SRL
        run_test(`OPC_ARI_RTYPE, `FNC_SRL_SRA, 7'b0100000); // SRA

        // I-type arithmetic
        run_test(`OPC_ARI_ITYPE, `FNC_ADD_SUB, 7'b0000000); // ADDI
        run_test(`OPC_ARI_ITYPE, `FNC_XOR,     7'b0000000); // XORI
        run_test(`OPC_ARI_ITYPE, `FNC_OR,      7'b0000000); // ORI
        run_test(`OPC_ARI_ITYPE, `FNC_AND,     7'b0000000); // ANDI
        run_test(`OPC_ARI_ITYPE, `FNC_SLT,     7'b0000000); // SLTI
        run_test(`OPC_ARI_ITYPE, `FNC_SLL,     7'b0000000); // SLLI
        run_test(`OPC_ARI_ITYPE, `FNC_SLTU,    7'b0000000); // SLTIU
        run_test(`OPC_ARI_ITYPE, `FNC_SRL_SRA, 7'b0000000); // SRLI
        run_test(`OPC_ARI_ITYPE, `FNC_SRL_SRA, 7'b0100000); // SRAI

        // ADD-only class
        run_test(`OPC_LOAD,   3'b000, 7'b0000000); // LOAD
        run_test(`OPC_STORE,  3'b010, 7'b0000000); // STORE
        run_test(`OPC_JAL,    3'b000, 7'b0000000); // JAL
        run_test(`OPC_JALR,   3'b000, 7'b0000000); // JALR
        run_test(`OPC_AUIPC,  3'b000, 7'b0000000); // AUIPC
        run_test(`OPC_LUI,    3'b000, 7'b0000000); // LUI

        // Branch class
        run_test(`OPC_BRANCH, `FNC_BEQ,  7'b0000000); // BEQ
        run_test(`OPC_BRANCH, `FNC_BNE,  7'b0000000); // BNE
        run_test(`OPC_BRANCH, `FNC_BLT,  7'b0000000); // BLT
        run_test(`OPC_BRANCH, `FNC_BGE,  7'b0000000); // BGE
        run_test(`OPC_BRANCH, `FNC_BLTU, 7'b0000000); // BLTU
        run_test(`OPC_BRANCH, `FNC_BGEU, 7'b0000000); // BGEU

        // CSR / reserved
        run_test(`OPC_CSR, 3'b000, 7'b0000000);

        // =========================================
        // Randomized testing
        // =========================================
        repeat (3000) begin
            case ($urandom_range(0, 4))

                // Random R-type arithmetic
                0: begin
                    case ($urandom_range(0, 9))
                        0: run_test(`OPC_ARI_RTYPE, `FNC_ADD_SUB, 7'b0000000);
                        1: run_test(`OPC_ARI_RTYPE, `FNC_ADD_SUB, 7'b0100000);
                        2: run_test(`OPC_ARI_RTYPE, `FNC_XOR,     7'b0000000);
                        3: run_test(`OPC_ARI_RTYPE, `FNC_OR,      7'b0000000);
                        4: run_test(`OPC_ARI_RTYPE, `FNC_AND,     7'b0000000);
                        5: run_test(`OPC_ARI_RTYPE, `FNC_SLT,     7'b0000000);
                        6: run_test(`OPC_ARI_RTYPE, `FNC_SLL,     7'b0000000);
                        7: run_test(`OPC_ARI_RTYPE, `FNC_SLTU,    7'b0000000);
                        8: run_test(`OPC_ARI_RTYPE, `FNC_SRL_SRA, 7'b0000000);
                        9: run_test(`OPC_ARI_RTYPE, `FNC_SRL_SRA, 7'b0100000);
                    endcase
                end

                // Random I-type arithmetic
                1: begin
                    case ($urandom_range(0, 8))
                        0: run_test(`OPC_ARI_ITYPE, `FNC_ADD_SUB, 7'b0000000);
                        1: run_test(`OPC_ARI_ITYPE, `FNC_XOR,     7'b0000000);
                        2: run_test(`OPC_ARI_ITYPE, `FNC_OR,      7'b0000000);
                        3: run_test(`OPC_ARI_ITYPE, `FNC_AND,     7'b0000000);
                        4: run_test(`OPC_ARI_ITYPE, `FNC_SLT,     7'b0000000);
                        5: run_test(`OPC_ARI_ITYPE, `FNC_SLL,     7'b0000000);
                        6: run_test(`OPC_ARI_ITYPE, `FNC_SLTU,    7'b0000000);
                        7: run_test(`OPC_ARI_ITYPE, `FNC_SRL_SRA, 7'b0000000);
                        8: run_test(`OPC_ARI_ITYPE, `FNC_SRL_SRA, 7'b0100000);
                    endcase
                end

                // Random ADD-only class
                2: begin
                    case ($urandom_range(0, 5))
                        0: run_test(`OPC_LOAD,  3'b000, 7'b0000000);
                        1: run_test(`OPC_STORE, 3'b010, 7'b0000000);
                        2: run_test(`OPC_JAL,   3'b000, 7'b0000000);
                        3: run_test(`OPC_JALR,  3'b000, 7'b0000000);
                        4: run_test(`OPC_AUIPC, 3'b000, 7'b0000000);
                        5: run_test(`OPC_LUI,   3'b000, 7'b0000000);
                    endcase
                end

                // Random branch class
                3: begin
                    case ($urandom_range(0, 5))
                        0: run_test(`OPC_BRANCH, `FNC_BEQ,  7'b0000000);
                        1: run_test(`OPC_BRANCH, `FNC_BNE,  7'b0000000);
                        2: run_test(`OPC_BRANCH, `FNC_BLT,  7'b0000000);
                        3: run_test(`OPC_BRANCH, `FNC_BGE,  7'b0000000);
                        4: run_test(`OPC_BRANCH, `FNC_BLTU, 7'b0000000);
                        5: run_test(`OPC_BRANCH, `FNC_BGEU, 7'b0000000);
                    endcase
                end

                // Random CSR / reserved
                4: begin
                    run_test(`OPC_CSR, 3'b000, 7'b0000000);
                end
            endcase
        end

        // Display summary
        $display("Controller Testing Finished");
        $display("Total Tests  : %0d", total_tests);
        $display("Passed Tests : %0d", passed_tests);
        $display("Failed Tests : %0d", failed_tests);

        if (failed_tests == 0)
            $display("ALL CONTROLLER TESTS PASSED");
        else
            $display("SOME CONTROLLER TESTS FAILED");

        $finish;
    end

endmodule