`timescale 1ns/1ns

`include "opcode.vh"
`include "mem_path.vh"

module cpu_pipeline_final_tb();

    logic clk;
    logic rst;

    parameter CPU_CLOCK_PERIOD = 20;

    localparam logic [31:0] RESET_PC_VALUE = 32'h1000_0000;
    localparam logic [31:0] NOP_INST       = 32'h0000_0013;

    int total_tests;
    int pass_count;
    int fail_count;

    int forwarding_expected_count;
    int forwarding_implemented_count;
    int flushing_expected_count;
    int flushing_implemented_count;

    int cycle_count;
    integer i;

    logic [31:0] expected_target;
    logic        expected_rs1_forward;
    logic        expected_rs2_forward;

    // Machine code was generated/confirmed using the RISC-V toolchain.

    // R-type instructions
    localparam logic [31:0] INST_ADD_X3_X1_X2  = 32'h0020_81b3; // add  x3,  x1, x2
    localparam logic [31:0] INST_SUB_X4_X1_X2  = 32'h4020_8233; // sub  x4,  x1, x2
    localparam logic [31:0] INST_SLL_X5_X1_X2  = 32'h0020_92b3; // sll  x5,  x1, x2
    localparam logic [31:0] INST_SLT_X6_X1_X2  = 32'h0020_a333; // slt  x6,  x1, x2
    localparam logic [31:0] INST_SLTU_X7_X1_X2 = 32'h0020_b3b3; // sltu x7,  x1, x2
    localparam logic [31:0] INST_XOR_X8_X1_X2  = 32'h0020_c433; // xor  x8,  x1, x2
    localparam logic [31:0] INST_SRL_X9_X1_X2  = 32'h0020_d4b3; // srl  x9,  x1, x2
    localparam logic [31:0] INST_SRA_X10_X1_X2 = 32'h4020_d533; // sra  x10, x1, x2
    localparam logic [31:0] INST_OR_X11_X1_X2  = 32'h0020_e5b3; // or   x11, x1, x2
    localparam logic [31:0] INST_AND_X12_X1_X2 = 32'h0020_f633; // and  x12, x1, x2

    // I-type arithmetic instructions
    localparam logic [31:0] INST_ADDI_X13_X1_10 = 32'h00a0_8693; // addi  x13, x1, 10
    localparam logic [31:0] INST_SLLI_X14_X1_3  = 32'h0030_9713; // slli  x14, x1, 3
    localparam logic [31:0] INST_SLTI_X15_X1_10 = 32'h00a0_a793; // slti  x15, x1, 10
    localparam logic [31:0] INST_SLTIU_X16_X1_10= 32'h00a0_b813; // sltiu x16, x1, 10
    localparam logic [31:0] INST_XORI_X17_X1_15 = 32'h00f0_c893; // xori  x17, x1, 15
    localparam logic [31:0] INST_SRLI_X18_X1_2  = 32'h0020_d913; // srli  x18, x1, 2
    localparam logic [31:0] INST_SRAI_X19_X1_2  = 32'h4020_d993; // srai  x19, x1, 2
    localparam logic [31:0] INST_ORI_X20_X1_15  = 32'h00f0_ea13; // ori   x20, x1, 15
    localparam logic [31:0] INST_ANDI_X21_X1_15 = 32'h00f0_fa93; // andi  x21, x1, 15

    // Load instructions
    localparam logic [31:0] INST_LB_X22_1_X1  = 32'h0010_8b03; // lb  x22, 1(x1)
    localparam logic [31:0] INST_LH_X23_2_X1  = 32'h0020_9b83; // lh  x23, 2(x1)
    localparam logic [31:0] INST_LW_X24_4_X1  = 32'h0040_ac03; // lw  x24, 4(x1)
    localparam logic [31:0] INST_LBU_X25_1_X1 = 32'h0010_cc83; // lbu x25, 1(x1)
    localparam logic [31:0] INST_LHU_X26_2_X1 = 32'h0020_dd03; // lhu x26, 2(x1)

    // Store instructions
    localparam logic [31:0] INST_SB_X2_8_X1   = 32'h0020_8423; // sb x2,  8(x1)
    localparam logic [31:0] INST_SH_X2_10_X1  = 32'h0020_9523; // sh x2, 10(x1)
    localparam logic [31:0] INST_SW_X2_12_X1  = 32'h0020_a623; // sw x2, 12(x1)

    // U, B, and J instructions
    localparam logic [31:0] INST_LUI_X27_12345 = 32'h1234_5db7; // lui x27, 0x12345
    localparam logic [31:0] INST_BEQ_X1_X2_8   = 32'h0020_8463; // beq x1, x2, +8
    localparam logic [31:0] INST_BNE_X1_X2_8   = 32'h0020_9463; // bne x1, x2, +8
    localparam logic [31:0] INST_JAL_X10_8     = 32'h0080_056f; // jal x10, +8

    // Hazard sequence instructions
    localparam logic [31:0] INST_ADD_X4_X3_X2 = 32'h0021_8233; // add x4, x3, x2
    localparam logic [31:0] INST_ADD_X4_X3_X3 = 32'h0031_8233; // add x4, x3, x3
    localparam logic [31:0] INST_SUB_X4_X2_X3 = 32'h4031_0233; // sub x4, x2, x3
    localparam logic [31:0] INST_ADD_X5_X1_X2 = 32'h0020_82b3; // add x5, x1, x2
    localparam logic [31:0] INST_LW_X6_0_X5   = 32'h0002_a303; // lw  x6, 0(x5)
    localparam logic [31:0] INST_LW_X6_0_X1   = 32'h0000_a303; // lw  x6, 0(x1)
    localparam logic [31:0] INST_ADD_X7_X6_X2 = 32'h0023_03b3; // add x7, x6, x2
    localparam logic [31:0] INST_SW_X6_4_X1   = 32'h0060_a223; // sw  x6, 4(x1)
    localparam logic [31:0] INST_SW_X6_8_X0   = 32'h0060_2423; // sw  x6, 8(x0)
    localparam logic [31:0] INST_BEQ_X3_X4_8  = 32'h0041_8463; // beq x3, x4, +8
    localparam logic [31:0] INST_BNE_X3_X4_8  = 32'h0041_9463; // bne x3, x4, +8
    localparam logic [31:0] INST_ADDI_X31_1   = 32'h0010_0f93; // addi x31, x0, 1
    localparam logic [31:0] INST_ADDI_X30_2   = 32'h0020_0f13; // addi x30, x0, 2
    localparam logic [31:0] INST_ADD_X0_X1_X2 = 32'h0020_8033; // add x0, x1, x2
    localparam logic [31:0] INST_ADD_X3_X0_X2 = 32'h0020_01b3; // add x3, x0, x2


    cpu cpu (
        .clk (clk),
        .rst (rst)
    );


    initial begin
        clk = 1'b0;
        forever #(CPU_CLOCK_PERIOD/2) clk = ~clk;
    end


    function logic uses_rs1;
        input logic [31:0] instruction;
        logic [6:0] opcode;

        begin
            opcode = instruction[6:0];

            case (opcode)

                7'b0110011: uses_rs1 = 1'b1; // R-type
                7'b0010011: uses_rs1 = 1'b1; // I-type arithmetic
                7'b0000011: uses_rs1 = 1'b1; // load
                7'b0100011: uses_rs1 = 1'b1; // store
                7'b1100011: uses_rs1 = 1'b1; // branch

                7'b0110111: uses_rs1 = 1'b0; // lui
                7'b1101111: uses_rs1 = 1'b0; // jal

                default:    uses_rs1 = 1'b0;

            endcase
        end
    endfunction


    function logic uses_rs2;
        input logic [31:0] instruction;
        logic [6:0] opcode;

        begin
            opcode = instruction[6:0];

            case (opcode)

                7'b0110011: uses_rs2 = 1'b1; // R-type
                7'b0100011: uses_rs2 = 1'b1; // store
                7'b1100011: uses_rs2 = 1'b1; // branch

                default:    uses_rs2 = 1'b0;

            endcase
        end
    endfunction


    task clear_all;
        begin

            for (i = 0; i < 32; i = i + 1) begin
                `REGFILE_PATH.Registers[i] = 32'b0;
            end

            for (i = 0; i < 16384; i = i + 1) begin
                `DMEM_PATH.memory[i] = 32'b0;
            end

            for (i = 0; i < 16384; i = i + 1) begin
                `IMEM_PATH.memory[i] = NOP_INST;
            end

        end
    endtask


    task reset_cpu;
        begin
            rst = 1'b1;
            @(posedge clk);
            #1;
            rst = 1'b0;
        end
    endtask


    task set_inst;
        input int index;
        input logic [31:0] instruction;

        begin
            `IMEM_PATH.memory[index] = instruction;
        end
    endtask


    task start_case;
        input string test_name;

        begin
            $display("");
            $display("============================================================");
            $display("%s", test_name);
            $display("============================================================");

            clear_all();
        end
    endtask


    task check_reg;
        input logic [4:0]  reg_addr;
        input logic [31:0] expected;
        input string       check_name;

        logic [31:0] actual;

        begin
            actual = `REGFILE_PATH.Registers[reg_addr];
            total_tests = total_tests + 1;

            if (actual === expected) begin
                pass_count = pass_count + 1;
                $display("[PASS] %s | x%0d = %h", check_name, reg_addr, actual);
            end

            else begin
                fail_count = fail_count + 1;
                $display("[FAIL] %s | x%0d expected=%h actual=%h",
                         check_name, reg_addr, expected, actual);
            end
        end
    endtask


    task check_mem_word;
        input logic [31:0] addr;
        input logic [31:0] expected;
        input string       check_name;

        logic [31:0] actual;

        begin
            actual = `DMEM_PATH.memory[addr[15:2]];
            total_tests = total_tests + 1;

            if (actual === expected) begin
                pass_count = pass_count + 1;
                $display("[PASS] %s | mem[%h] = %h", check_name, addr, actual);
            end

            else begin
                fail_count = fail_count + 1;
                $display("[FAIL] %s | mem[%h] expected=%h actual=%h",
                         check_name, addr, expected, actual);
            end
        end
    endtask


    task check_forwarding_at_cycle;
        begin
            expected_rs1_forward = dx_mw_writes_real_register() &&
                                   uses_rs1(cpu.if_dx_instr) &&
                                   (cpu.dx_mw_rd_addr == cpu.rs1_addr);

            expected_rs2_forward = dx_mw_writes_real_register() &&
                                   uses_rs2(cpu.if_dx_instr) &&
                                   (cpu.dx_mw_rd_addr == cpu.rs2_addr);

            if (expected_rs1_forward) begin
                forwarding_expected_count = forwarding_expected_count + 1;
                total_tests = total_tests + 1;

                $display("  Forwarding expected on rs1 | DX rs1=x%0d MW rd=x%0d",
                         cpu.rs1_addr, cpu.dx_mw_rd_addr);

                if (cpu.forward_rs1) begin
                    forwarding_implemented_count = forwarding_implemented_count + 1;
                    pass_count = pass_count + 1;
                    $display("  [PASS] forward_rs1 asserted");
                end

                else begin
                    fail_count = fail_count + 1;
                    $display("  [FAIL] forward_rs1 was not asserted");
                end
            end

            if (expected_rs2_forward) begin
                forwarding_expected_count = forwarding_expected_count + 1;
                total_tests = total_tests + 1;

                $display("  Forwarding expected on rs2 | DX rs2=x%0d MW rd=x%0d",
                         cpu.rs2_addr, cpu.dx_mw_rd_addr);

                if (cpu.forward_rs2) begin
                    forwarding_implemented_count = forwarding_implemented_count + 1;
                    pass_count = pass_count + 1;
                    $display("  [PASS] forward_rs2 asserted");
                end

                else begin
                    fail_count = fail_count + 1;
                    $display("  [FAIL] forward_rs2 was not asserted");
                end
            end
        end
    endtask


    function logic dx_mw_writes_real_register;
        begin
            dx_mw_writes_real_register = cpu.dx_mw_RegWrite &&
                                         (cpu.dx_mw_rd_addr != 5'd0);
        end
    endfunction


    task monitor_and_advance_one_cycle;
        begin
            check_forwarding_at_cycle();

            if (cpu.br_taken) begin
                expected_target = cpu.alu_result;
                flushing_expected_count = flushing_expected_count + 1;
                total_tests = total_tests + 1;

                $display("  Flushing expected | br_taken=1 target=%h", expected_target);

                @(posedge clk);
                #1;

                if ((cpu.if_dx_instr === NOP_INST) && (cpu.pc_curr === expected_target)) begin
                    flushing_implemented_count = flushing_implemented_count + 1;
                    pass_count = pass_count + 1;
                    $display("  [PASS] flush implemented | IF/DX=Nop PC=%h", cpu.pc_curr);
                end

                else begin
                    fail_count = fail_count + 1;
                    $display("  [FAIL] flush failed | IF/DX=%h PC=%h expected_PC=%h",
                             cpu.if_dx_instr, cpu.pc_curr, expected_target);
                end
            end

            else begin
                @(posedge clk);
                #1;
            end
        end
    endtask


    task run_cycles;
        input int cycles;

        begin
            for (cycle_count = 0; cycle_count < cycles; cycle_count = cycle_count + 1) begin
                @(negedge clk);
                monitor_and_advance_one_cycle();
            end
        end
    endtask


    task run_instruction_functionality_tests;
        begin
            $display("");
            $display("############################################################");
            $display("# SPLIT 1: INSTRUCTION FUNCTIONALITY TESTS");
            $display("############################################################");

            start_case("Instruction functionality: R-type, I-type, load, store, LUI");

            `REGFILE_PATH.Registers[1] = 32'd16;
            `REGFILE_PATH.Registers[2] = 32'd2;

            `DMEM_PATH.memory[32'h0000_0010 >> 2] = 32'habcd_807f;
            `DMEM_PATH.memory[32'h0000_0014 >> 2] = 32'h1122_3344;
            `DMEM_PATH.memory[32'h0000_0018 >> 2] = 32'h0000_0000;
            `DMEM_PATH.memory[32'h0000_001c >> 2] = 32'h0000_0000;

            set_inst(0,  INST_ADD_X3_X1_X2);
            set_inst(1,  INST_SUB_X4_X1_X2);
            set_inst(2,  INST_SLL_X5_X1_X2);
            set_inst(3,  INST_SLT_X6_X1_X2);
            set_inst(4,  INST_SLTU_X7_X1_X2);
            set_inst(5,  INST_XOR_X8_X1_X2);
            set_inst(6,  INST_SRL_X9_X1_X2);
            set_inst(7,  INST_SRA_X10_X1_X2);
            set_inst(8,  INST_OR_X11_X1_X2);
            set_inst(9,  INST_AND_X12_X1_X2);

            set_inst(10, INST_ADDI_X13_X1_10);
            set_inst(11, INST_SLLI_X14_X1_3);
            set_inst(12, INST_SLTI_X15_X1_10);
            set_inst(13, INST_SLTIU_X16_X1_10);
            set_inst(14, INST_XORI_X17_X1_15);
            set_inst(15, INST_SRLI_X18_X1_2);
            set_inst(16, INST_SRAI_X19_X1_2);
            set_inst(17, INST_ORI_X20_X1_15);
            set_inst(18, INST_ANDI_X21_X1_15);

            set_inst(19, INST_LB_X22_1_X1);
            set_inst(20, INST_LH_X23_2_X1);
            set_inst(21, INST_LW_X24_4_X1);
            set_inst(22, INST_LBU_X25_1_X1);
            set_inst(23, INST_LHU_X26_2_X1);

            set_inst(24, INST_SB_X2_8_X1);
            set_inst(25, INST_SH_X2_10_X1);
            set_inst(26, INST_SW_X2_12_X1);

            set_inst(27, INST_LUI_X27_12345);

            reset_cpu();
            run_cycles(36);

            check_reg(5'd3,  32'd18,        "ADD");
            check_reg(5'd4,  32'd14,        "SUB");
            check_reg(5'd5,  32'd64,        "SLL");
            check_reg(5'd6,  32'd0,         "SLT");
            check_reg(5'd7,  32'd0,         "SLTU");
            check_reg(5'd8,  32'd18,        "XOR");
            check_reg(5'd9,  32'd4,         "SRL");
            check_reg(5'd10, 32'd4,         "SRA");
            check_reg(5'd11, 32'd18,        "OR");
            check_reg(5'd12, 32'd0,         "AND");

            check_reg(5'd13, 32'd26,        "ADDI");
            check_reg(5'd14, 32'd128,       "SLLI");
            check_reg(5'd15, 32'd0,         "SLTI");
            check_reg(5'd16, 32'd0,         "SLTIU");
            check_reg(5'd17, 32'd31,        "XORI");
            check_reg(5'd18, 32'd4,         "SRLI");
            check_reg(5'd19, 32'd4,         "SRAI");
            check_reg(5'd20, 32'd31,        "ORI");
            check_reg(5'd21, 32'd0,         "ANDI");

            check_reg(5'd22, 32'hffff_ff80, "LB");
            check_reg(5'd23, 32'hffff_abcd, "LH");
            check_reg(5'd24, 32'h1122_3344, "LW");
            check_reg(5'd25, 32'h0000_0080, "LBU");
            check_reg(5'd26, 32'h0000_abcd, "LHU");

            check_mem_word(32'h0000_0018, 32'h0002_0002, "SB followed by SH");
            check_mem_word(32'h0000_001c, 32'h0000_0002, "SW");

            check_reg(5'd27, 32'h1234_5000, "LUI");


            start_case("Instruction functionality: BEQ taken");

            `REGFILE_PATH.Registers[1] = 32'd5;
            `REGFILE_PATH.Registers[2] = 32'd5;

            set_inst(0, INST_BEQ_X1_X2_8);
            set_inst(1, INST_ADDI_X31_1);
            set_inst(2, INST_ADDI_X30_2);

            reset_cpu();
            run_cycles(10);

            check_reg(5'd31, 32'd0, "BEQ taken: wrong-path instruction flushed");
            check_reg(5'd30, 32'd2, "BEQ taken: target instruction executed");


            start_case("Instruction functionality: BNE taken");

            `REGFILE_PATH.Registers[1] = 32'd5;
            `REGFILE_PATH.Registers[2] = 32'd6;

            set_inst(0, INST_BNE_X1_X2_8);
            set_inst(1, INST_ADDI_X31_1);
            set_inst(2, INST_ADDI_X30_2);

            reset_cpu();
            run_cycles(10);

            check_reg(5'd31, 32'd0, "BNE taken: wrong-path instruction flushed");
            check_reg(5'd30, 32'd2, "BNE taken: target instruction executed");


            start_case("Instruction functionality: BEQ not taken");

            `REGFILE_PATH.Registers[1] = 32'd5;
            `REGFILE_PATH.Registers[2] = 32'd6;

            set_inst(0, INST_BEQ_X1_X2_8);
            set_inst(1, INST_ADDI_X31_1);

            reset_cpu();
            run_cycles(8);

            check_reg(5'd31, 32'd1, "BEQ not taken: next sequential instruction executed");


            start_case("Instruction functionality: JAL");

            set_inst(0, INST_JAL_X10_8);
            set_inst(1, INST_ADDI_X31_1);
            set_inst(2, INST_ADDI_X30_2);

            reset_cpu();
            run_cycles(10);

            check_reg(5'd10, 32'h1000_0004, "JAL link register PC + 4");
            check_reg(5'd31, 32'd0,         "JAL: wrong-path instruction flushed");
            check_reg(5'd30, 32'd2,         "JAL: target instruction executed");
        end
    endtask


    task run_hazard_sequence_tests;
        int flush_before;

        begin
            $display("");
            $display("############################################################");
            $display("# SPLIT 2: HAZARD SEQUENCE TESTS");
            $display("############################################################");


            start_case("Hazard 1: ALU-to-ALU RAW on rs1");
            $display("Expected: add produces x3, next add uses x3 as rs1. forward_rs1 must assert.");

            `REGFILE_PATH.Registers[1] = 32'd5;
            `REGFILE_PATH.Registers[2] = 32'd7;

            set_inst(0, INST_ADD_X3_X1_X2);
            set_inst(1, INST_ADD_X4_X3_X2);

            reset_cpu();
            run_cycles(8);

            check_reg(5'd3, 32'd12, "Producer ADD result");
            check_reg(5'd4, 32'd19, "Consumer ADD result after rs1 forwarding");


            start_case("Hazard 2: ALU-to-ALU RAW on rs2");
            $display("Expected: add produces x3, next sub uses x3 as rs2. forward_rs2 must assert.");

            `REGFILE_PATH.Registers[1] = 32'd5;
            `REGFILE_PATH.Registers[2] = 32'd7;

            set_inst(0, INST_ADD_X3_X1_X2);
            set_inst(1, INST_SUB_X4_X2_X3);

            reset_cpu();
            run_cycles(8);

            check_reg(5'd3, 32'd12,        "Producer ADD result");
            check_reg(5'd4, 32'hffff_fffb, "Consumer SUB result after rs2 forwarding");


            start_case("Hazard 3: ALU-to-ALU RAW on both rs1 and rs2");
            $display("Expected: add produces x3, next add uses x3 as both operands. forward_rs1 and forward_rs2 must assert.");

            `REGFILE_PATH.Registers[1] = 32'd5;
            `REGFILE_PATH.Registers[2] = 32'd7;

            set_inst(0, INST_ADD_X3_X1_X2);
            set_inst(1, INST_ADD_X4_X3_X3);

            reset_cpu();
            run_cycles(8);

            check_reg(5'd3, 32'd12, "Producer ADD result");
            check_reg(5'd4, 32'd24, "Consumer ADD result after dual forwarding");


            start_case("Hazard 4: ALU result used as load base address");
            $display("Expected: add produces x5 = base address, next lw uses x5 as rs1. forward_rs1 must assert.");

            `REGFILE_PATH.Registers[1] = 32'h0000_0100;
            `REGFILE_PATH.Registers[2] = 32'h0000_0004;
            `DMEM_PATH.memory[32'h0000_0104 >> 2] = 32'hcafe_babe;

            set_inst(0, INST_ADD_X5_X1_X2);
            set_inst(1, INST_LW_X6_0_X5);

            reset_cpu();
            run_cycles(8);

            check_reg(5'd5, 32'h0000_0104, "Forwarded address producer");
            check_reg(5'd6, 32'hcafe_babe, "Load using forwarded base address");


            start_case("Hazard 5: Load-use RAW dependency");
            $display("Expected: lw produces x6, next add uses x6 as rs1. forward_rs1 must assert. No bubble is required.");

            `REGFILE_PATH.Registers[1] = 32'h0000_0100;
            `REGFILE_PATH.Registers[2] = 32'h0000_0001;
            `DMEM_PATH.memory[32'h0000_0100 >> 2] = 32'h0000_0010;

            set_inst(0, INST_LW_X6_0_X1);
            set_inst(1, INST_ADD_X7_X6_X2);

            reset_cpu();
            run_cycles(8);

            check_reg(5'd6, 32'h0000_0010, "Load result");
            check_reg(5'd7, 32'h0000_0011, "ADD result after load-use forwarding");


            start_case("Hazard 6: Load result used as store data");
            $display("Expected: lw produces x6, next sw uses x6 as store data rs2. forward_rs2 must assert.");

            `REGFILE_PATH.Registers[1] = 32'h0000_0100;
            `DMEM_PATH.memory[32'h0000_0100 >> 2] = 32'hdead_beef;
            `DMEM_PATH.memory[32'h0000_0104 >> 2] = 32'h0000_0000;

            set_inst(0, INST_LW_X6_0_X1);
            set_inst(1, INST_SW_X6_4_X1);

            reset_cpu();
            run_cycles(8);

            check_reg(5'd6, 32'hdead_beef, "Load result");
            check_mem_word(32'h0000_0104, 32'hdead_beef, "Store data forwarded from load");


            start_case("Hazard 7: ALU result used as store data");
            $display("Expected: add produces x6, next sw uses x6 as store data rs2. forward_rs2 must assert.");

            `REGFILE_PATH.Registers[1] = 32'd5;
            `REGFILE_PATH.Registers[2] = 32'd7;
            `DMEM_PATH.memory[32'h0000_0008 >> 2] = 32'h0000_0000;

            set_inst(0, INST_ADD_X3_X1_X2);
            set_inst(1, INST_SW_X6_8_X0);

            // Make x6 dependent using same producer value path:
            // x6 is intentionally set by changing producer output through register file check below.
            // Therefore use an explicit producer for x6.
            `IMEM_PATH.memory[0] = 32'h0020_8333; // add x6, x1, x2

            reset_cpu();
            run_cycles(8);

            check_reg(5'd6, 32'd12, "Producer ADD result for store data");
            check_mem_word(32'h0000_0008, 32'd12, "Store data forwarded from ALU result");


            start_case("Hazard 8: Branch comparison uses forwarded ALU result");
            $display("Expected: add produces x3, following beq compares x3 with x4. forward_rs1 and flush must occur.");
            $display("Expected branch target: 0x1000000c");

            `REGFILE_PATH.Registers[1] = 32'd5;
            `REGFILE_PATH.Registers[2] = 32'd7;
            `REGFILE_PATH.Registers[4] = 32'd12;

            set_inst(0, INST_ADD_X3_X1_X2);
            set_inst(1, INST_BEQ_X3_X4_8);
            set_inst(2, INST_ADDI_X31_1);
            set_inst(3, INST_ADDI_X30_2);

            reset_cpu();
            run_cycles(12);

            check_reg(5'd3,  32'd12, "Producer ADD result");
            check_reg(5'd31, 32'd0,  "Wrong-path instruction flushed");
            check_reg(5'd30, 32'd2,  "Branch target instruction executed");


            start_case("Hazard 9: Branch not taken must not flush");
            $display("Expected: bne condition is false, so flushing must not occur and sequential instruction must execute.");

            flush_before = flushing_expected_count;

            `REGFILE_PATH.Registers[3] = 32'd12;
            `REGFILE_PATH.Registers[4] = 32'd12;

            set_inst(0, INST_BNE_X3_X4_8);
            set_inst(1, INST_ADDI_X31_1);

            reset_cpu();
            run_cycles(8);

            check_reg(5'd31, 32'd1, "Sequential instruction executed after not-taken branch");

            total_tests = total_tests + 1;
            if (flushing_expected_count == flush_before) begin
                pass_count = pass_count + 1;
                $display("[PASS] No flush occurred for not-taken branch");
            end
            else begin
                fail_count = fail_count + 1;
                $display("[FAIL] Unexpected flush occurred for not-taken branch");
            end


            start_case("Hazard 10: JAL control hazard and flushing");
            $display("Expected: jal always redirects PC. Wrong-path instruction must be flushed.");
            $display("Expected jump target: 0x10000008");

            set_inst(0, INST_JAL_X10_8);
            set_inst(1, INST_ADDI_X31_1);
            set_inst(2, INST_ADDI_X30_2);

            reset_cpu();
            run_cycles(10);

            check_reg(5'd10, 32'h1000_0004, "JAL writes PC + 4");
            check_reg(5'd31, 32'd0,         "Wrong-path instruction flushed after JAL");
            check_reg(5'd30, 32'd2,         "JAL target instruction executed");


            start_case("Hazard 11: x0 destination must not cause forwarding");
            $display("Expected: add writes x0, next add reads x0. No real forwarding should affect the result.");

            `REGFILE_PATH.Registers[1] = 32'd5;
            `REGFILE_PATH.Registers[2] = 32'd7;

            set_inst(0, INST_ADD_X0_X1_X2);
            set_inst(1, INST_ADD_X3_X0_X2);

            reset_cpu();
            run_cycles(8);

            check_reg(5'd0, 32'd0, "x0 remains zero");
            check_reg(5'd3, 32'd7, "Consumer correctly reads x0 as zero");
        end
    endtask


    initial begin
        rst = 1'b0;

        total_tests = 0;
        pass_count  = 0;
        fail_count  = 0;

        forwarding_expected_count    = 0;
        forwarding_implemented_count = 0;
        flushing_expected_count      = 0;
        flushing_implemented_count   = 0;

        $display("");
        $display("============================================================");
        $display("FINAL 3-STAGE PIPELINED PROCESSOR SELF-TESTING TESTBENCH");
        $display("Tests instruction functionality, forwarding, and flushing.");
        $display("No waveform debugging is required for pass/fail decision.");
        $display("============================================================");

        run_instruction_functionality_tests();
        run_hazard_sequence_tests();

        $display("");
        $display("============================================================");
        $display("FINAL TEST SUMMARY");
        $display("============================================================");
        $display("Total tests passed                 = %0d", pass_count);
        $display("Total tests failed                 = %0d", fail_count);
        $display("Total checks                       = %0d", total_tests);
        $display("");
        $display("Forwarding expected events         = %0d", forwarding_expected_count);
        $display("Forwarding implemented events      = %0d", forwarding_implemented_count);
        $display("Flushing expected events           = %0d", flushing_expected_count);
        $display("Flushing implemented events        = %0d", flushing_implemented_count);
        $display("============================================================");

        if (fail_count == 0) begin
            $display("FINAL RESULT: ALL TESTS PASSED");
        end
        else begin
            $display("FINAL RESULT: SOME TESTS FAILED");
        end

        $display("============================================================");

        repeat (2) @(posedge clk);
        $finish;
    end

endmodule