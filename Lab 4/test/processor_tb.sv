`timescale 1ns/1ps
`include "opcode.vh"

module processor_tb;

    // Clock and reset
    logic clk;
    logic rst;

    // DUT debug outputs
    logic [31:0] pc_curr;
    logic [31:0] instruction;
    logic [31:0] immediate_out;
    logic [31:0] rs1_data_out;
    logic [31:0] rs2_data_out;
    logic [31:0] alu_result_out;
    logic [31:0] wr_data_out;
    logic [3:0]  alu_operation_out;
    logic        zero_out;

    // Counters
    integer total_checks;
    integer passed_checks;
    integer failed_checks;

    // DUT instantiation
    processor dut
    (
        .clk              (clk),
        .rst              (rst),
        .pc_curr          (pc_curr),
        .instruction      (instruction),
        .immediate_out    (immediate_out),
        .rs1_data_out     (rs1_data_out),
        .rs2_data_out     (rs2_data_out),
        .alu_result_out   (alu_result_out),
        .wr_data_out      (wr_data_out),
        .alu_operation_out(alu_operation_out),
        .zero_out         (zero_out)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Instruction encoder helpers
    function automatic logic [31:0] encode_r;
        input logic [6:0] funct7;
        input logic [4:0] rs2;
        input logic [4:0] rs1;
        input logic [2:0] funct3;
        input logic [4:0] rd;
        input logic [6:0] opcode;
        begin
            encode_r = {funct7, rs2, rs1, funct3, rd, opcode};
        end
    endfunction

    function automatic logic [31:0] encode_i;
        input logic signed [11:0] imm12;
        input logic [4:0]         rs1;
        input logic [2:0]         funct3;
        input logic [4:0]         rd;
        input logic [6:0]         opcode;
        begin
            encode_i = {imm12, rs1, funct3, rd, opcode};
        end
    endfunction

    // Utility tasks

    task automatic clear_imem;
        integer i;
        begin
            for (i = 0; i < dut.u_instr_mem.DEPTH; i++) begin
                dut.u_instr_mem.mem[i] = `INST_NOP;
            end
        end
    endtask

    task automatic reset_dut;
        begin
            rst = 1'b1;
            #2;
            rst = 1'b0;
            #2;
        end
    endtask

    task automatic seed_regs_for_r_and_i;
        begin
            dut.u_register_file.regs[1]  = 32'd10;          // x1  = 10
            dut.u_register_file.regs[2]  = 32'd3;           // x2  = 3
            dut.u_register_file.regs[15] = 32'hFFFF_FFF8;   // x15 = -8
            dut.u_register_file.regs[0]  = 32'd0;           // x0  = 0
        end
    endtask

    task automatic step_cycle;
        logic [31:0] pc_before;
        logic [31:0] instr_before;
        begin
            pc_before   = pc_curr;
            instr_before = instruction;
            @(posedge clk);
            #1;
            $display("time=%0t executed_pc=%h executed_instr=%h -> next_pc=%h result=%h wb=%h zero=%b",
                     $time, pc_before, instr_before, pc_curr, alu_result_out, wr_data_out, zero_out);
        end
    endtask

    task automatic check_reg;
        input logic [4:0]  reg_idx;
        input logic [31:0] expected;
        input string       msg;
        begin
            total_checks = total_checks + 1;
            if (dut.u_register_file.regs[reg_idx] === expected) begin
                passed_checks = passed_checks + 1;
                $display("PASS: %s | x%0d = %h", msg, reg_idx, dut.u_register_file.regs[reg_idx]);
            end
            else begin
                failed_checks = failed_checks + 1;
                $display("FAIL: %s | x%0d = %h, expected = %h",
                         msg, reg_idx, dut.u_register_file.regs[reg_idx], expected);
            end
        end
    endtask

    task automatic check_signal;
        input logic expected;
        input logic actual;
        input string msg;
        begin
            total_checks = total_checks + 1;
            if (actual === expected) begin
                passed_checks = passed_checks + 1;
                $display("PASS: %s | value = %b", msg, actual);
            end
            else begin
                failed_checks = failed_checks + 1;
                $display("FAIL: %s | value = %b, expected = %b", msg, actual, expected);
            end
        end
    endtask

    // Program loaders
    task automatic load_rtype_program;
        begin
            clear_imem();

            // R-type only program
            dut.u_instr_mem.mem[0]  = encode_r(`FNC7_0, 5'd2,  5'd1,  `FNC_ADD_SUB, 5'd3,  `OPC_ARI_RTYPE); // add  x3,  x1, x2
            dut.u_instr_mem.mem[1]  = encode_r(`FNC7_1, 5'd2,  5'd1,  `FNC_ADD_SUB, 5'd4,  `OPC_ARI_RTYPE); // sub  x4,  x1, x2
            dut.u_instr_mem.mem[2]  = encode_r(`FNC7_0, 5'd2,  5'd1,  `FNC_XOR,     5'd5,  `OPC_ARI_RTYPE); // xor  x5,  x1, x2
            dut.u_instr_mem.mem[3]  = encode_r(`FNC7_0, 5'd2,  5'd1,  `FNC_OR,      5'd6,  `OPC_ARI_RTYPE); // or   x6,  x1, x2
            dut.u_instr_mem.mem[4]  = encode_r(`FNC7_0, 5'd2,  5'd1,  `FNC_AND,     5'd7,  `OPC_ARI_RTYPE); // and  x7,  x1, x2
            dut.u_instr_mem.mem[5]  = encode_r(`FNC7_0, 5'd2,  5'd15, `FNC_SLT,     5'd8,  `OPC_ARI_RTYPE); // slt  x8,  x15, x2
            dut.u_instr_mem.mem[6]  = encode_r(`FNC7_0, 5'd2,  5'd1,  `FNC_SLL,     5'd9,  `OPC_ARI_RTYPE); // sll  x9,  x1, x2
            dut.u_instr_mem.mem[7]  = encode_r(`FNC7_0, 5'd2,  5'd15, `FNC_SLTU,    5'd10, `OPC_ARI_RTYPE); // sltu x10, x15, x2
            dut.u_instr_mem.mem[8]  = encode_r(`FNC7_0, 5'd2,  5'd15, `FNC_SRL_SRA, 5'd11, `OPC_ARI_RTYPE); // srl  x11, x15, x2
            dut.u_instr_mem.mem[9]  = encode_r(`FNC7_1, 5'd2,  5'd15, `FNC_SRL_SRA, 5'd12, `OPC_ARI_RTYPE); // sra  x12, x15, x2
            dut.u_instr_mem.mem[10] = encode_r(`FNC7_1, 5'd1,  5'd1,  `FNC_ADD_SUB, 5'd13, `OPC_ARI_RTYPE); // sub  x13, x1, x1
        end
    endtask

    task automatic load_itype_program;
        begin
            clear_imem();

            // I-type only program
            dut.u_instr_mem.mem[0] = encode_i(12'sd12,  5'd1,  `FNC_ADD_SUB, 5'd3,  `OPC_ARI_ITYPE); // addi  x3,  x1, 12
            dut.u_instr_mem.mem[1] = encode_i(12'sd7,   5'd1,  `FNC_XOR,     5'd4,  `OPC_ARI_ITYPE); // xori  x4,  x1, 7
            dut.u_instr_mem.mem[2] = encode_i(12'sd4,   5'd1,  `FNC_OR,      5'd5,  `OPC_ARI_ITYPE); // ori   x5,  x1, 4
            dut.u_instr_mem.mem[3] = encode_i(12'sd6,   5'd1,  `FNC_AND,     5'd6,  `OPC_ARI_ITYPE); // andi  x6,  x1, 6
            dut.u_instr_mem.mem[4] = encode_i(12'sd0,   5'd15, `FNC_SLT,     5'd7,  `OPC_ARI_ITYPE); // slti  x7,  x15, 0
            dut.u_instr_mem.mem[5] = encode_i(12'sd4,   5'd2,  `FNC_SLL,     5'd8,  `OPC_ARI_ITYPE); // slli  x8,  x2, 4
            dut.u_instr_mem.mem[6] = encode_i(12'sd5,   5'd15, `FNC_SLTU,    5'd9,  `OPC_ARI_ITYPE); // sltiu x9,  x15, 5
            dut.u_instr_mem.mem[7] = encode_i(12'sd2,   5'd15, `FNC_SRL_SRA, 5'd10, `OPC_ARI_ITYPE); // srli  x10, x15, 2
            dut.u_instr_mem.mem[8] = encode_i(12'h402,  5'd15, `FNC_SRL_SRA, 5'd11, `OPC_ARI_ITYPE); // srai  x11, x15, 2
            dut.u_instr_mem.mem[9] = encode_i(-12'sd5,  5'd0,  `FNC_ADD_SUB, 5'd12, `OPC_ARI_ITYPE); // addi  x12, x0, -5
        end
    endtask

    task automatic load_mixed_program;
        begin
            clear_imem();

            // Mixed R-type and I-type program
            dut.u_instr_mem.mem[0]  = encode_i(12'sd5,   5'd0,  `FNC_ADD_SUB, 5'd1,  `OPC_ARI_ITYPE); // addi x1,  x0, 5
            dut.u_instr_mem.mem[1]  = encode_i(12'sd12,  5'd0,  `FNC_ADD_SUB, 5'd2,  `OPC_ARI_ITYPE); // addi x2,  x0, 12
            dut.u_instr_mem.mem[2]  = encode_r(`FNC7_1,  5'd1,  5'd2, `FNC_ADD_SUB, 5'd3, `OPC_ARI_RTYPE); // sub  x3,  x2, x1
            dut.u_instr_mem.mem[3]  = encode_i(12'sd10,  5'd2,  `FNC_AND,     5'd4,  `OPC_ARI_ITYPE); // andi x4,  x2, 10
            dut.u_instr_mem.mem[4]  = encode_r(`FNC7_0,  5'd4,  5'd3, `FNC_OR,      5'd5, `OPC_ARI_RTYPE); // or   x5,  x3, x4
            dut.u_instr_mem.mem[5]  = encode_i(12'sd1,   5'd5,  `FNC_SLL,     5'd6,  `OPC_ARI_ITYPE); // slli x6,  x5, 1
            dut.u_instr_mem.mem[6]  = encode_r(`FNC7_0,  5'd2,  5'd1, `FNC_SLT,     5'd7, `OPC_ARI_RTYPE); // slt  x7,  x1, x2
            dut.u_instr_mem.mem[7]  = encode_i(12'sd3,   5'd6,  `FNC_XOR,     5'd8,  `OPC_ARI_ITYPE); // xori x8,  x6, 3
            dut.u_instr_mem.mem[8]  = encode_i(-12'sd16, 5'd0,  `FNC_ADD_SUB, 5'd10, `OPC_ARI_ITYPE); // addi x10, x0, -16
            dut.u_instr_mem.mem[9]  = encode_i(12'h402,  5'd10, `FNC_SRL_SRA, 5'd11, `OPC_ARI_ITYPE); // srai x11, x10, 2
            dut.u_instr_mem.mem[10] = encode_r(`FNC7_0,  5'd7,  5'd11,`FNC_ADD_SUB, 5'd12, `OPC_ARI_RTYPE); // add  x12, x11, x7
        end
    endtask

    // Test sequences
    task automatic test_rtype_sequence;
        begin
            $display("\n================ R-TYPE TEST SEQUENCE ================");
            reset_dut();
            load_rtype_program();
            seed_regs_for_r_and_i();

            step_cycle(); check_reg(5'd3,  32'd13,        "add  x3,  x1,  x2");
            step_cycle(); check_reg(5'd4,  32'd7,         "sub  x4,  x1,  x2");
            step_cycle(); check_reg(5'd5,  32'd9,         "xor  x5,  x1,  x2");
            step_cycle(); check_reg(5'd6,  32'd11,        "or   x6,  x1,  x2");
            step_cycle(); check_reg(5'd7,  32'd2,         "and  x7,  x1,  x2");
            step_cycle(); check_reg(5'd8,  32'd1,         "slt  x8,  x15, x2");
            step_cycle(); check_reg(5'd9,  32'd80,        "sll  x9,  x1,  x2");
            step_cycle(); check_reg(5'd10, 32'd0,         "sltu x10, x15, x2");
            step_cycle(); check_reg(5'd11, 32'h1FFF_FFFF, "srl  x11, x15, x2");
            step_cycle(); check_reg(5'd12, 32'hFFFF_FFFF, "sra  x12, x15, x2");
            step_cycle(); begin
                check_reg(5'd13, 32'd0, "sub  x13, x1, x1");
            end
        end
    endtask

    task automatic test_itype_sequence;
        begin
            $display("\n================ I-TYPE TEST SEQUENCE ================");
            reset_dut();
            load_itype_program();
            seed_regs_for_r_and_i();

            step_cycle(); check_reg(5'd3,  32'd22,        "addi  x3,  x1,  12");
            step_cycle(); check_reg(5'd4,  32'd13,        "xori  x4,  x1,  7");
            step_cycle(); check_reg(5'd5,  32'd14,        "ori   x5,  x1,  4");
            step_cycle(); check_reg(5'd6,  32'd2,         "andi  x6,  x1,  6");
            step_cycle(); check_reg(5'd7,  32'd1,         "slti  x7,  x15, 0");
            step_cycle(); check_reg(5'd8,  32'd48,        "slli  x8,  x2,  4");
            step_cycle(); check_reg(5'd9,  32'd0,         "sltiu x9,  x15, 5");
            step_cycle(); check_reg(5'd10, 32'h3FFF_FFFE, "srli  x10, x15, 2");
            step_cycle(); check_reg(5'd11, 32'hFFFF_FFFE, "srai  x11, x15, 2");
            step_cycle(); check_reg(5'd12, 32'hFFFF_FFFB, "addi  x12, x0, -5");
        end
    endtask

    task automatic test_mixed_sequence;
        begin
            $display("\n================ MIXED R/I TEST SEQUENCE ================");
            reset_dut();
            load_mixed_program();

            step_cycle(); check_reg(5'd1,  32'd5,         "addi x1,  x0,  5");
            step_cycle(); check_reg(5'd2,  32'd12,        "addi x2,  x0,  12");
            step_cycle(); check_reg(5'd3,  32'd7,         "sub  x3,  x2,  x1");
            step_cycle(); check_reg(5'd4,  32'd8,         "andi x4,  x2,  10");
            step_cycle(); check_reg(5'd5,  32'd15,        "or   x5,  x3,  x4");
            step_cycle(); check_reg(5'd6,  32'd30,        "slli x6,  x5,  1");
            step_cycle(); check_reg(5'd7,  32'd1,         "slt  x7,  x1,  x2");
            step_cycle(); check_reg(5'd8,  32'd29,        "xori x8,  x6,  3");
            step_cycle(); check_reg(5'd10, 32'hFFFF_FFF0, "addi x10, x0, -16");
            step_cycle(); check_reg(5'd11, 32'hFFFF_FFFC, "srai x11, x10, 2");
            step_cycle(); check_reg(5'd12, 32'hFFFF_FFFD, "add  x12, x11, x7");
        end
    endtask

    // Main test flow
    initial begin
        total_checks  = 0;
        passed_checks = 0;
        failed_checks = 0;
        rst           = 1'b0;

        test_rtype_sequence();
        test_itype_sequence();
        test_mixed_sequence();

        $display("\n================ TEST SUMMARY ================");
        $display("Total checks  = %0d", total_checks);
        $display("Passed checks = %0d", passed_checks);
        $display("Failed checks = %0d", failed_checks);

        if (failed_checks == 0) begin
            $display("ALL TESTS PASSED");
        end
        else begin
            $display("SOME TESTS FAILED");
        end

        #20;
        $stop;
    end

endmodule
