`timescale 1ns/1ns

`include "opcode.vh"
`include "mem_path.vh"

module tb_with_hazard();

    logic clk;
    logic rst;

    parameter CPU_CLOCK_PERIOD = 20;
    localparam logic [31:0] NOP_INST = 32'h0000_0013;

    integer i;

    logic [31:0] mw_instr_dbg;

    logic [31:0] dbg_pc_curr;
    logic [31:0] dbg_pc_next;
    logic [31:0] dbg_if_instr;
    logic [31:0] dbg_dx_instr;
    logic [31:0] dbg_mw_instr;

    logic [31:0] dbg_rs1_data;
    logic [31:0] dbg_rs2_data;
    logic [31:0] dbg_rs1_fwd;
    logic [31:0] dbg_rs2_fwd;
    logic [31:0] dbg_alu_result;
    logic [31:0] dbg_wr_data;

    logic        dbg_forward_rs1;
    logic        dbg_forward_rs2;
    logic        dbg_br_taken;

    // Machine code confirmed from RISC-V toolchain.
    localparam logic [31:0] INST_ADDI_X1_X0_6  = 32'h0060_0093;
    localparam logic [31:0] INST_ADDI_X2_X0_2  = 32'h0020_0113;
    localparam logic [31:0] INST_ADD_X4_X1_X2  = 32'h0020_8233;
    localparam logic [31:0] INST_SW_X4_20_X0   = 32'h0240_2023;
    localparam logic [31:0] INST_LW_X9_20_X0   = 32'h0200_2483;
    localparam logic [31:0] INST_ADD_X5_X9_X2  = 32'h0024_82b3;
    localparam logic [31:0] INST_ADD_X11_X1_X2 = 32'h0020_85b3;
    localparam logic [31:0] INST_BEQ_X4_X11_LABEL = 32'h00b2_0663;
    localparam logic [31:0] INST_ADDI_X9_X0_2  = 32'h0020_0493;
    localparam logic [31:0] INST_ADDI_X4_X0_16 = 32'h0100_0213;
    localparam logic [31:0] INST_OR_X2_X9_X4   = 32'h0044_e133;


    cpu cpu (
        .clk (clk),
        .rst (rst)
    );


    initial begin
        clk = 1'b0;
        forever #(CPU_CLOCK_PERIOD/2) clk = ~clk;
    end


    assign dbg_pc_curr     = cpu.pc_curr;
    assign dbg_pc_next     = cpu.pc_next;
    assign dbg_if_instr    = cpu.instr;
    assign dbg_dx_instr    = cpu.if_dx_instr;
    assign dbg_mw_instr    = mw_instr_dbg;

    assign dbg_rs1_data    = cpu.rs1_data;
    assign dbg_rs2_data    = cpu.rs2_data;
    assign dbg_rs1_fwd     = cpu.rs1_fwd;
    assign dbg_rs2_fwd     = cpu.rs2_fwd;
    assign dbg_alu_result  = cpu.alu_result;
    assign dbg_wr_data     = cpu.wr_data;

    assign dbg_forward_rs1 = cpu.forward_rs1;
    assign dbg_forward_rs2 = cpu.forward_rs2;
    assign dbg_br_taken    = cpu.br_taken;


    always @(posedge clk or posedge rst) begin

        if (rst) begin
            mw_instr_dbg <= NOP_INST;
        end

        else begin
            mw_instr_dbg <= cpu.if_dx_instr;
        end

    end


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


    task load_program;
        begin

            `IMEM_PATH.memory[0]  = INST_ADDI_X1_X0_6;
            `IMEM_PATH.memory[1]  = INST_ADDI_X2_X0_2;
            `IMEM_PATH.memory[2]  = INST_ADD_X4_X1_X2;
            `IMEM_PATH.memory[3]  = INST_SW_X4_20_X0;
            `IMEM_PATH.memory[4]  = INST_LW_X9_20_X0;
            `IMEM_PATH.memory[5]  = INST_ADD_X5_X9_X2;
            `IMEM_PATH.memory[6]  = INST_ADD_X11_X1_X2;
            `IMEM_PATH.memory[7]  = INST_BEQ_X4_X11_LABEL;
            `IMEM_PATH.memory[8]  = INST_ADDI_X9_X0_2;
            `IMEM_PATH.memory[9]  = INST_ADDI_X4_X0_16;
            `IMEM_PATH.memory[10] = INST_OR_X2_X9_X4;

            `IMEM_PATH.memory[11] = NOP_INST;
            `IMEM_PATH.memory[12] = NOP_INST;
            `IMEM_PATH.memory[13] = NOP_INST;
            `IMEM_PATH.memory[14] = NOP_INST;

        end
    endtask


    task reset_cpu;
        begin
            rst = 1'b1;
            repeat (2) @(posedge clk);
            #1;
            rst = 1'b0;
        end
    endtask


    initial begin

        $dumpfile("tb_with_hazard.vcd");
        $dumpvars(0, tb_with_hazard);

        rst = 1'b0;

        clear_all();
        load_program();
        reset_cpu();

        repeat (24) @(posedge clk);

        $display("");
        $display("============================================================");
        $display("WITH HAZARD PROGRAM FINAL RESULTS");
        $display("============================================================");
        $display("Expected x1  = 00000006 | Actual x1  = %h", `REGFILE_PATH.Registers[1]);
        $display("Expected x2  = 00000008 | Actual x2  = %h", `REGFILE_PATH.Registers[2]);
        $display("Expected x4  = 00000008 | Actual x4  = %h", `REGFILE_PATH.Registers[4]);
        $display("Expected x5  = 0000000a | Actual x5  = %h", `REGFILE_PATH.Registers[5]);
        $display("Expected x9  = 00000008 | Actual x9  = %h", `REGFILE_PATH.Registers[9]);
        $display("Expected x11 = 00000008 | Actual x11 = %h", `REGFILE_PATH.Registers[11]);
        $display("Expected mem[0x20] = 00000008 | Actual = %h", `DMEM_PATH.memory[32'h20 >> 2]);
        $display("============================================================");

        #20;
        $finish;

    end

endmodule