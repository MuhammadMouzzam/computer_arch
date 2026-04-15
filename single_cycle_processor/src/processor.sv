module processor
#(
    parameter logic [31:0] RESET_PC   = 32'h0000_0000,
    parameter int unsigned IMEM_DEPTH = 256,
    parameter int unsigned DMEM_DEPTH = 256,
    parameter string       IMEM_FILE  = "",
    parameter string       DMEM_FILE  = ""
)
(
    input  logic        clk,
    input  logic        rst,

    // Optional debug outputs for simulation / waveform checking
    output logic [31:0] pc_curr,
    output logic [31:0] instruction,
    output logic [31:0] immediate_out,
    output logic [31:0] rs1_data_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] alu_result_out,
    output logic [31:0] wr_data_out,
    output logic [3:0]  alu_operation_out,
    output logic        zero_out
);

    // ------------------------------------------------------------
    // Internal signals
    // ------------------------------------------------------------
    logic [31:0] pc_next;

    logic [2:0]  ALUOp;
    logic        MemRead;
    logic        MemtoReg;
    logic        MemWrite;
    logic        ALUSrc;
    logic        RegWrite;

    logic [4:0]  rs1_addr;
    logic [4:0]  rs2_addr;
    logic [4:0]  rd_addr;

    logic [2:0]  func3;
    logic [6:0]  func7;

    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] immediate;

    logic [31:0] alu_operand2;
    logic [3:0]  alu_operation;
    logic [31:0] result;
    logic        zero;

    logic [31:0] rdata;
    logic        dmem_misaligned;

    logic [31:0] wr_data;

    // ------------------------------------------------------------
    // Instruction field extraction
    // ------------------------------------------------------------
    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    assign rd_addr  = instruction[11:7];
    assign func3    = instruction[14:12];
    assign func7    = instruction[31:25];

    // ------------------------------------------------------------
    // Next PC logic
    // For current Lab 4 R/I arithmetic subset:
    // always go to next sequential instruction
    // ------------------------------------------------------------
    assign pc_next = pc_curr + 32'd4;

    // ------------------------------------------------------------
    // ALU input selection
    // R-type  -> operand2 = rs2_data
    // I-type  -> operand2 = immediate
    // ------------------------------------------------------------
    assign alu_operand2 = (ALUSrc) ? immediate : rs2_data;

    // ------------------------------------------------------------
    // Writeback selection
    // For R/I arithmetic, MemtoReg = 0 so ALU result is written back.
    // Kept generic so load integration is easier later.
    // ------------------------------------------------------------
    assign wr_data = (MemtoReg) ? rdata : result;

    // ------------------------------------------------------------
    // Module instantiations
    // ------------------------------------------------------------

    // Program Counter
    pc
    #(
        .RESET_PC(RESET_PC)
    )
    u_pc
    (
        .clk    (clk),
        .rst    (rst),
        .pc_we  (1'b1),
        .pc_next(pc_next),
        .pc_curr(pc_curr)
    );

    // Instruction Memory
    instr_mem
    #(
        .DEPTH    (IMEM_DEPTH),
        .INIT_FILE(IMEM_FILE)
    )
    u_instr_mem
    (
        .addr (pc_curr),
        .instr(instruction)
    );

    // First-Level Controller
    alu_first_level_controller u_first_level_controller
    (
        .instr    (instruction),
        .ALUOp    (ALUOp),
        .MemRead  (MemRead),
        .MemtoReg (MemtoReg),
        .MemWrite (MemWrite),
        .ALUSrc   (ALUSrc),
        .RegWrite (RegWrite)
    );

    // Register File
    register_file
    #(
        .XLEN     (32),
        .REG_COUNT(32)
    )
    u_register_file
    (
        .clk     (clk),
        .rst     (rst),
        .we      (RegWrite),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr (rd_addr),
        .wr_data (wr_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // Immediate Generator
    immediate_generator u_immediate_generator
    (
        .instruction(instruction),
        .immediate  (immediate)
    );

    // Second-Level ALU Controller
    alu_second_level_controller u_second_level_controller
    (
        .ALUOp        (ALUOp),
        .func3        (func3),
        .func7        (func7),
        .alu_operation(alu_operation)
    );

    // ALU
    alu u_alu
    (
        .operand1     (rs1_data),
        .operand2     (alu_operand2),
        .alu_operation(alu_operation),
        .result       (result),
        .zero         (zero)
    );

    // Data Memory
    // Instantiated for full datapath structure and future extension.
    // For current Lab 4 R/I arithmetic program, this should remain unused.
    data_mem
    #(
        .DEPTH    (DMEM_DEPTH),
        .INIT_FILE(DMEM_FILE)
    )
    u_data_mem
    (
        .clk       (clk),
        .mem_read  (MemRead),
        .mem_write (MemWrite),
        .funct3    (func3),
        .addr      (result),
        .write_data(rs2_data),
        .read_data (rdata),
        .misaligned(dmem_misaligned)
    );

    // ------------------------------------------------------------
    // Debug outputs
    // ------------------------------------------------------------
    assign immediate_out      = immediate;
    assign rs1_data_out       = rs1_data;
    assign rs2_data_out       = rs2_data;
    assign alu_result_out     = result;
    assign wr_data_out = wr_data;
    assign alu_operation_out  = alu_operation;
    assign zero_out           = zero;

endmodule