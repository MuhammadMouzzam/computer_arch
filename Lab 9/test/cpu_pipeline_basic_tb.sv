`timescale 1ns/1ns

`include "opcode.vh"
`include "mem_path.vh"

module cpu_pipeline_basic_tb();

    logic clk;
    logic rst;

    parameter CPU_CLOCK_PERIOD = 20;
    parameter int TRACE_CYCLES = 3;

    int test_id;
    int pass_count;
    int cycle_id;
    integer i;

    localparam logic [31:0] NOP_INST = 32'h0000_0013;

    // Machine code generated/verified from RV32I assembly instructions
    // Currently manual / separate for instruction-wise verification.
    // $readmemh can be used in final full-program testing.
    localparam logic [31:0] INST_ADD   = 32'h0020_81b3;  // add  x3, x1, x2
    localparam logic [31:0] INST_SUB   = 32'h4020_8233;  // sub  x4, x1, x2
    localparam logic [31:0] INST_ADDI  = 32'h00a0_8293;  // addi x5, x1, 10
    localparam logic [31:0] INST_ANDI  = 32'h00f0_f313;  // andi x6, x1, 15
    localparam logic [31:0] INST_LW    = 32'h0000_a383;  // lw   x7, 0(x1)
    localparam logic [31:0] INST_SW    = 32'h0020_a023;  // sw   x2, 0(x1)
    localparam logic [31:0] INST_LUI   = 32'h1234_5437;  // lui  x8, 0x12345

    logic [31:0] mw_instr_dbg;


    cpu cpu (
        .clk (clk),
        .rst (rst)
    );


    initial begin
        clk = 1'b0;
        forever #(CPU_CLOCK_PERIOD/2) clk = ~clk;
    end


    // Debug-only tracker for instruction currently represented by MW-stage signals.
    // This does not modify the CPU. It only helps terminal printing.
    always @(posedge clk or posedge rst) begin

        if (rst) begin
            mw_instr_dbg <= NOP_INST;
        end

        else begin
            mw_instr_dbg <= cpu.if_dx_instr;
        end

    end


    function string instr_name;
        input logic [31:0] instruction;

        begin

            case (instruction)

                NOP_INST: begin
                    instr_name = "NOP";
                end

                INST_ADD: begin
                    instr_name = "ADD x3,x1,x2";
                end

                INST_SUB: begin
                    instr_name = "SUB x4,x1,x2";
                end

                INST_ADDI: begin
                    instr_name = "ADDI x5,x1,10";
                end

                INST_ANDI: begin
                    instr_name = "ANDI x6,x1,15";
                end

                INST_LW: begin
                    instr_name = "LW x7,0(x1)";
                end

                INST_SW: begin
                    instr_name = "SW x2,0(x1)";
                end

                INST_LUI: begin
                    instr_name = "LUI x8,0x12345";
                end

                default: begin
                    instr_name = $sformatf("UNKNOWN %h", instruction);
                end

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


    task load_single_instruction;
        input logic [31:0] instruction;
        begin
            `IMEM_PATH.memory[0] = instruction;
            `IMEM_PATH.memory[1] = NOP_INST;
            `IMEM_PATH.memory[2] = NOP_INST;
            `IMEM_PATH.memory[3] = NOP_INST;
            `IMEM_PATH.memory[4] = NOP_INST;
            `IMEM_PATH.memory[5] = NOP_INST;
        end
    endtask


    task print_pipeline_state;
        input int cycle_num;

        begin
            $display("");
            $display("------------------------------------------------------------");
            $display("CLOCK CYCLE %0d", cycle_num);
            $display("------------------------------------------------------------");

            $display("IF : %-18s | pc=%h | instr=%h | pc_next=%h",
                     instr_name(cpu.instr),
                     cpu.pc_curr,
                     cpu.instr,
                     cpu.pc_next);

            $display("DX : %-18s | pc=%h | rs1=x%0d rs2=x%0d rd=x%0d",
                     instr_name(cpu.if_dx_instr),
                     cpu.if_dx_pc,
                     cpu.rs1_addr,
                     cpu.rs2_addr,
                     cpu.rd_addr);

            $display("     rs1_data=%h | rs2_data=%h | imm=%h",
                     cpu.rs1_data,
                     cpu.rs2_data,
                     cpu.immediate);

            $display("     op1=%h | op2=%h | alu_result=%h",
                     cpu.alu_operand1,
                     cpu.alu_operand2,
                     cpu.alu_result);

            $display("     control: RegWrite=%b MemRead=%b MemWrite=%b wb_sel=%b br_taken=%b",
                     cpu.RegWrite,
                     cpu.MemRead,
                     cpu.MemWrite,
                     cpu.wb_sel,
                     cpu.br_taken);

            $display("MW : %-18s | rd=x%0d | result=%h | rdata=%h | wr_data=%h",
                     instr_name(mw_instr_dbg),
                     cpu.dx_mw_rd_addr,
                     cpu.dx_mw_result,
                     cpu.rdata,
                     cpu.wr_data);

            $display("     control: RegWrite=%b MemRead=%b MemWrite=%b wb_sel=%b",
                     cpu.dx_mw_RegWrite,
                     cpu.dx_mw_MemRead,
                     cpu.dx_mw_MemWrite,
                     cpu.dx_mw_wb_sel);

            if (cpu.dx_mw_RegWrite && (cpu.dx_mw_rd_addr != 5'd0)) begin
                $display("     COMMIT AT NEXT RISING EDGE: x%0d <= %h",
                         cpu.dx_mw_rd_addr,
                         cpu.wr_data);
            end

            if (cpu.dx_mw_MemWrite) begin
                $display("     MEMORY WRITE AT NEXT RISING EDGE: addr=%h data=%h",
                         cpu.dx_mw_result,
                         cpu.dx_mw_wdata);
            end

        end
    endtask


    task run_trace;
        begin

            for (cycle_id = 1; cycle_id <= TRACE_CYCLES; cycle_id = cycle_id + 1) begin
                @(negedge clk);
                print_pipeline_state(cycle_id);
                @(posedge clk);
                #1;
            end

            $display("");
            $display("Final commit edge completed. Checking result now.");

        end
    endtask


    task check_register;
        input logic [4:0]  reg_addr;
        input logic [31:0] expected;
        input string       test_name;

        logic [31:0] actual;

        begin
            actual = `REGFILE_PATH.Registers[reg_addr];

            $display("");
            $display("RESULT CHECK: %s", test_name);
            $display("  Expected RF[x%0d] = %h", reg_addr, expected);
            $display("  Actual   RF[x%0d] = %h", reg_addr, actual);

            if (actual !== expected) begin
                $display("[FAILED] %s", test_name);
                $finish;
            end

            else begin
                $display("[PASSED] %s", test_name);
                pass_count = pass_count + 1;
            end

        end
    endtask


    task check_memory;
        input logic [31:0] addr;
        input logic [31:0] expected;
        input string       test_name;

        logic [31:0] actual;

        begin
            actual = `DMEM_PATH.memory[addr[15:2]];

            $display("");
            $display("RESULT CHECK: %s", test_name);
            $display("  Expected DMEM[%h] = %h", addr, expected);
            $display("  Actual   DMEM[%h] = %h", addr, actual);

            if (actual !== expected) begin
                $display("[FAILED] %s", test_name);
                $finish;
            end

            else begin
                $display("[PASSED] %s", test_name);
                pass_count = pass_count + 1;
            end

        end
    endtask


    task start_test;
        input string test_name;

        begin
            test_id = test_id + 1;

            $display("");
            $display("============================================================");
            $display("TEST %0d: %s", test_id, test_name);
            $display("============================================================");

            clear_all();
        end
    endtask


    task test_r_type_add;
        begin
            start_test("R-Type ADD: add x3, x1, x2");

            `REGFILE_PATH.Registers[1] = 32'd5;
            `REGFILE_PATH.Registers[2] = 32'd7;

            load_single_instruction(INST_ADD);
            reset_cpu();
            run_trace();

            check_register(5'd3, 32'd12, "R-Type ADD");
        end
    endtask


    task test_r_type_sub;
        begin
            start_test("R-Type SUB: sub x4, x1, x2");

            `REGFILE_PATH.Registers[1] = 32'd20;
            `REGFILE_PATH.Registers[2] = 32'd8;

            load_single_instruction(INST_SUB);
            reset_cpu();
            run_trace();

            check_register(5'd4, 32'd12, "R-Type SUB");
        end
    endtask


    task test_i_type_addi;
        begin
            start_test("I-Type ADDI: addi x5, x1, 10");

            `REGFILE_PATH.Registers[1] = 32'd15;

            load_single_instruction(INST_ADDI);
            reset_cpu();
            run_trace();

            check_register(5'd5, 32'd25, "I-Type ADDI");
        end
    endtask


    task test_i_type_andi;
        begin
            start_test("I-Type ANDI: andi x6, x1, 15");

            `REGFILE_PATH.Registers[1] = 32'h0000_00ff;

            load_single_instruction(INST_ANDI);
            reset_cpu();
            run_trace();

            check_register(5'd6, 32'h0000_000f, "I-Type ANDI");
        end
    endtask


    task test_load_word;
        begin
            start_test("I-Type LOAD: lw x7, 0(x1)");

            `REGFILE_PATH.Registers[1] = 32'h0000_0100;
            `DMEM_PATH.memory[32'h0000_0100 >> 2] = 32'hdead_beef;

            load_single_instruction(INST_LW);
            reset_cpu();
            run_trace();

            check_register(5'd7, 32'hdead_beef, "I-Type LW");
        end
    endtask


    task test_store_word;
        begin
            start_test("S-Type STORE: sw x2, 0(x1)");

            `REGFILE_PATH.Registers[1] = 32'h0000_0100;
            `REGFILE_PATH.Registers[2] = 32'h1234_5678;
            `DMEM_PATH.memory[32'h0000_0100 >> 2] = 32'b0;

            load_single_instruction(INST_SW);
            reset_cpu();
            run_trace();

            check_memory(32'h0000_0100, 32'h1234_5678, "S-Type SW");
        end
    endtask


    task test_u_type_lui;
        begin
            start_test("U-Type LUI: lui x8, 0x12345");

            load_single_instruction(INST_LUI);
            reset_cpu();
            run_trace();

            check_register(5'd8, 32'h1234_5000, "U-Type LUI");
        end
    endtask


    initial begin
        rst = 1'b0;
        test_id = 0;
        pass_count = 0;

        $display("");
        $display("============================================================");
        $display("3-STAGE PIPELINED PROCESSOR BASIC DATAPATH TESTBENCH");
        $display("Clock-by-clock IF/DX/MW trace is printed.");
        $display("Branches, jumps, and hazard cases are tested separately in Experiment 10.");
        $display("============================================================");

        test_r_type_add();
        test_r_type_sub();
        test_i_type_addi();
        test_i_type_andi();
        test_load_word();
        test_store_word();
        test_u_type_lui();

        $display("");
        $display("============================================================");
        $display("ALL BASIC PIPELINED DATAPATH TESTS PASSED");
        $display("Total tests passed = %0d", pass_count);
        $display("============================================================");

        repeat (2) @(posedge clk);
        $finish;
    end

endmodule