`timescale 1ns/1ps

// Include for MACROS
`include "opcode.vh"

module imm_generator_tb;

    // DUT signals
    logic [31:0] instruction;
    logic [31:0] immediate;
    logic [31:0] expected_immediate;

    // Test results
    int total_tests  = 0;
    int passed_tests = 0;
    int failed_tests = 0;

    // DUT instance
    immediate_generator imm_generator_inst (
        .instruction(instruction),
        .immediate(immediate)
    );

    // Reference model for immediate generation
    function automatic logic [31:0] expected_imm(input logic [31:0] instr);

        logic [6:0] opcode;

        begin
            opcode = instr[6:0];

            case (opcode)

                // I-type
                `OPC_LOAD,
                `OPC_JALR,
                `OPC_ARI_ITYPE,
                `OPC_CSR:
                    expected_imm = {{20{instr[31]}}, instr[31:20]};

                // S-type
                `OPC_STORE:
                    expected_imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};

                // B-type
                `OPC_BRANCH:
                    expected_imm = {{19{instr[31]}},
                                    instr[31],
                                    instr[7],
                                    instr[30:25],
                                    instr[11:8],
                                    1'b0};

                // U-type
                `OPC_LUI,
                `OPC_AUIPC:
                    expected_imm = {instr[31:12], 12'b0};

                // J-type
                `OPC_JAL:
                    expected_imm = {{11{instr[31]}},
                                    instr[31],
                                    instr[19:12],
                                    instr[20],
                                    instr[30:21],
                                    1'b0};

                default:
                    expected_imm = 32'b0;

            endcase
        end

    endfunction

    // Helper function to print opcode name
    function automatic string opcode_name(input logic [6:0] opcode);

        case (opcode)
            `OPC_ARI_RTYPE : opcode_name = "OPC_ARI_RTYPE";
            `OPC_ARI_ITYPE : opcode_name = "OPC_ARI_ITYPE";
            `OPC_LOAD      : opcode_name = "OPC_LOAD";
            `OPC_STORE     : opcode_name = "OPC_STORE";
            `OPC_BRANCH    : opcode_name = "OPC_BRANCH";
            `OPC_JAL       : opcode_name = "OPC_JAL";
            `OPC_JALR      : opcode_name = "OPC_JALR";
            `OPC_AUIPC     : opcode_name = "OPC_AUIPC";
            `OPC_LUI       : opcode_name = "OPC_LUI";
            `OPC_CSR       : opcode_name = "OPC_CSR";
            default        : opcode_name = "UNKNOWN";
        endcase

    endfunction

    // Task to run a single test
    task automatic run_test(input logic [31:0] instr);

        begin
            instruction = instr;

            #1;

            expected_immediate = expected_imm(instr);

            total_tests++;

            if (immediate !== expected_immediate) begin
                failed_tests++;
                $display("FAIL | opcode=%s | instruction=0x%08h | immediate=0x%08h | expected_immediate=0x%08h",
                         opcode_name(instr[6:0]), instr, immediate, expected_immediate);
            end
            else begin
                passed_tests++;
            end
        end

    endtask

    // Random instruction generator
    function automatic logic [31:0] random_instruction();

        logic [31:0] instr;
        int sel;

        begin
            instr = 32'b0;
            sel   = $urandom_range(8, 0);

            case (sel)

                // I-type arithmetic
                0: begin
                    instr[31:7] = $urandom;
                    instr[6:0]  = `OPC_ARI_ITYPE;
                end

                // Load
                1: begin
                    instr[31:7] = $urandom;
                    instr[6:0]  = `OPC_LOAD;
                end

                // Store
                2: begin
                    instr[31:7] = $urandom;
                    instr[6:0]  = `OPC_STORE;
                end

                // Branch
                3: begin
                    instr[31:7] = $urandom;
                    instr[6:0]  = `OPC_BRANCH;
                end

                // JAL
                4: begin
                    instr[31:7] = $urandom;
                    instr[6:0]  = `OPC_JAL;
                end

                // JALR
                5: begin
                    instr[31:7] = $urandom;
                    instr[6:0]  = `OPC_JALR;
                end

                // AUIPC
                6: begin
                    instr[31:7] = $urandom;
                    instr[6:0]  = `OPC_AUIPC;
                end

                // LUI
                7: begin
                    instr[31:7] = $urandom;
                    instr[6:0]  = `OPC_LUI;
                end

                // CSR
                8: begin
                    instr[31:7] = $urandom;
                    instr[6:0]  = `OPC_CSR;
                end

                default: begin
                    instr = 32'b0;
                end

            endcase

            random_instruction = instr;
        end

    endfunction

    // Main testing block
    initial begin

        $display("Testing Immediate Generator");

        // Initialize
        instruction = 32'b0;
        #5;

        // Directed corner tests

        // I-type positive immediate
        run_test({12'h123, 5'd2, 3'b000, 5'd1, `OPC_ARI_ITYPE});

        // I-type negative immediate
        run_test({12'hFFF, 5'd2, 3'b000, 5'd1, `OPC_ARI_ITYPE});

        // S-type immediate
        run_test({7'b1010101, 5'd3, 5'd2, 3'b010, 5'b11001, `OPC_STORE});

        // B-type immediate
        run_test({1'b1, 6'b010101, 5'd3, 5'd2, 3'b000, 4'b1100, 1'b1, `OPC_BRANCH});

        // U-type immediate (LUI)
        run_test({20'hABCDE, 5'd1, `OPC_LUI});

        // J-type immediate (JAL)
        run_test({1'b1, 10'b0101010101, 1'b1, 8'hAA, 5'd1, `OPC_JAL});

        // Randomized tests
        repeat (5000) begin
            run_test(random_instruction());
        end

        // Summary
        $display("Immediate Generator Testing Finished");
        $display("Total Tests  : %0d", total_tests);
        $display("Passed Tests : %0d", passed_tests);
        $display("Failed Tests : %0d", failed_tests);

        if (failed_tests == 0)
            $display("ALL IMMEDIATE GENERATOR TESTS PASSED");
        else
            $display("SOME IMMEDIATE GENERATOR TESTS FAILED");

        $finish;
    end

endmodule