module cpu
#(
    parameter logic [31:0] RESET_PC   = 32'h1000_0000,
    parameter int unsigned IMEM_DEPTH = 16384,
    parameter int unsigned DMEM_DEPTH = 16384,
    parameter string       IMEM_FILE  = "",
    parameter string       DMEM_FILE  = ""
)
(
    input logic clk,
    input logic rst
);

    logic [31:0] pc_curr;
    logic [31:0] pc_next;
    logic [31:0] pc_plus_4;
    logic [31:0] instr;

    logic [4:0] rs1_addr;
    logic [4:0] rs2_addr;
    logic [4:0] rd_addr;

    logic [2:0] func3;
    logic [6:0] func7;

    logic        RegWrite;
    logic        ALUSRC_1;
    logic        ALUSRC_2;
    logic [2:0]  ALUOp;

    logic [2:0]  br_type;
    logic        br_en;

    logic        MemWrite;
    logic        MemRead;

    logic [1:0]  wb_sel;

    logic [31:0] immediate;

    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    logic [31:0] alu_operand1;
    logic [31:0] alu_operand2;

    logic [3:0]  alu_operation;
    logic [31:0] alu_result;
    logic        zero;

    logic        br_taken;

    logic [31:0] rdata;
    logic [31:0] wr_data;

    logic        RegWrite_en;
    logic        MemWrite_en;
    logic        MemRead_en;


    // Disable writes during reset
    assign RegWrite_en = RegWrite & ~rst;
    assign MemWrite_en = MemWrite & ~rst;
    assign MemRead_en  = MemRead  & ~rst;


    // Instruction fields
    assign rs1_addr = instr[19:15];
    assign rs2_addr = instr[24:20];
    assign rd_addr  = instr[11:7];

    assign func3    = instr[14:12];
    assign func7    = instr[31:25];


    // PC logic
    assign pc_plus_4 = pc_curr + 32'd4;
    assign pc_next   = br_taken ? alu_result : pc_plus_4;


    // ALU input muxes
    assign alu_operand1 = ALUSRC_1 ? pc_curr   : rs1_data;
    assign alu_operand2 = ALUSRC_2 ? immediate : rs2_data;


    // Writeback mux
    always_comb begin

        case (wb_sel)

            2'b00: begin
                wr_data = alu_result;
            end

            2'b01: begin
                wr_data = rdata;
            end

            2'b10: begin
                wr_data = pc_plus_4;
            end

            default: begin
                wr_data = 32'b0;
            end

        endcase

    end


    pc
    #(
        .RESET_PC(RESET_PC)
    )
    u_pc
    (
        .clk     (clk),
        .rst     (rst),
        .pc_next (pc_next),
        .pc_curr (pc_curr)
    );


    instr_mem
    #(
        .DEPTH     (IMEM_DEPTH),
        .INIT_FILE (IMEM_FILE)
    )
    u_instr_mem
    (
        .addr  (pc_curr),
        .instr (instr)
    );


    alu_first_level_controller u_first_level_controller
    (
        .instr     (instr),

        .RegWrite  (RegWrite),
        .ALUSRC_1  (ALUSRC_1),
        .ALUSRC_2  (ALUSRC_2),
        .ALUOp     (ALUOp),

        .br_type   (br_type),
        .br_en     (br_en),

        .MemWrite  (MemWrite),
        .MemRead   (MemRead),

        .wb_sel    (wb_sel)
    );


    register_file
    #(
        .XLEN      (32),
        .REG_COUNT (32)
    )
    u_register_file
    (
        .clk       (clk),
        .rst       (rst),
        .RegWrite  (RegWrite_en),

        .rs1_addr  (rs1_addr),
        .rs2_addr  (rs2_addr),
        .rd_addr   (rd_addr),

        .wr_data   (wr_data),

        .rs1_data  (rs1_data),
        .rs2_data  (rs2_data)
    );


    immediate_generator u_immediate_generator
    (
        .instr     (instr),
        .immediate (immediate)
    );


    alu_second_level_controller u_second_level_controller
    (
        .ALUOp         (ALUOp),
        .func3         (func3),
        .func7         (func7),
        .alu_operation (alu_operation)
    );


    alu u_alu
    (
        .operand1      (alu_operand1),
        .operand2      (alu_operand2),
        .alu_operation (alu_operation),
        .result        (alu_result),
        .zero          (zero)
    );


    branch_unit u_branch_unit
    (
        .rs1_data  (rs1_data),
        .rs2_data  (rs2_data),
        .br_type   (br_type),
        .br_en     (br_en),
        .br_taken  (br_taken)
    );


    data_mem
    #(
        .DEPTH     (DMEM_DEPTH),
        .INIT_FILE (DMEM_FILE)
    )
    u_data_mem
    (
        .clk       (clk),

        .MemRead   (MemRead_en),
        .MemWrite  (MemWrite_en),
        .funct3    (func3),

        .addr      (alu_result),
        .wdata     (rs2_data),

        .rdata     (rdata)
    );

endmodule