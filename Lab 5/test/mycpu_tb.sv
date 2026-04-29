`timescale 1ns/1ns

`include "opcode.vh"
`include "mem_path.vh"

module cpu_tb();

    reg clk;
    reg rst;

    parameter CPU_CLOCK_PERIOD = 20;

    reg [31:0]  cycle;
    reg         done;
    reg [31:0]  current_test_id;
    reg [255:0] current_test_type;
    reg [31:0]  current_output;
    reg [31:0]  current_result;
    reg         all_tests_passed;

    reg [4:0]  RD;
    reg [4:0]  RS1;
    reg [4:0]  RS2;
    reg [31:0] RD1;
    reg [31:0] RD2;
    reg [4:0]  SHAMT;
    reg [31:0] IMM;
    reg [31:0] IMM0;

    reg [31:0] INST_ADDR;
    reg [31:0] DATA_ADDR;
    reg [31:0] DATA_ADDR0;
    reg [31:0] JUMP_ADDR;

    reg [31:0] BR_TAKEN_OP1  [1:0];
    reg [31:0] BR_TAKEN_OP2  [1:0];
    reg [31:0] BR_NTAKEN_OP1 [1:0];
    reg [31:0] BR_NTAKEN_OP2 [1:0];
    reg [2:0]  BR_TYPE       [1:0];
    reg [255:0] BR_NAME_TK1  [1:0];
    reg [255:0] BR_NAME_TK2  [1:0];
    reg [255:0] BR_NAME_NTK  [1:0];

    initial clk = 1'b0;
    always #(CPU_CLOCK_PERIOD/2) clk = ~clk;

    cpu cpu (
        .clk (clk),
        .rst (rst)
    );

    wire [31:0] timeout_cycle = 32'd20;

    task reset;
        integer i;
        begin
            for (i = 0; i < 32; i = i + 1) begin
                `REGFILE_PATH.Registers[i] = 32'b0;
            end

            for (i = 0; i < 16384; i = i + 1) begin
                `DMEM_PATH.memory[i] = 32'b0;
            end

            for (i = 0; i < 16384; i = i + 1) begin
                `IMEM_PATH.memory[i] = 32'h0000_0013;
            end
        end
    endtask

    task reset_cpu;
        begin
            rst = 1'b1;
            @(posedge clk);
            #30;
            rst = 1'b0;
        end
    endtask

    task init_rf;
        integer i;
        begin
            for (i = 1; i < 32; i = i + 1) begin
                `REGFILE_PATH.Registers[i] = 100 * i + 1;
            end
        end
    endtask

    initial begin
        while (all_tests_passed === 1'b0) begin
            @(posedge clk);

            if (cycle === timeout_cycle) begin
                $display("[Failed] Timeout at [%0d] test %s, expected_result = %h, got = %h",
                         current_test_id, current_test_type, current_result, current_output);
                $finish();
            end
        end
    end

    always @(posedge clk) begin
        if (done === 1'b0) begin
            cycle <= cycle + 1;
        end
        else begin
            cycle <= 0;
        end
    end

    task check_result_rf;
        input [31:0]  rf_wa;
        input [31:0]  result;
        input [255:0] test_type;
        begin
            done = 1'b0;
            current_test_id   = current_test_id + 1;
            current_test_type = test_type;
            current_result    = result;

            while (`REGFILE_PATH.Registers[rf_wa] !== result) begin
                current_output = `REGFILE_PATH.Registers[rf_wa];
                @(negedge clk);
            end

            cycle = 0;
            done  = 1'b1;
            $display("[%0d] Test %s passed!", current_test_id, test_type);
        end
    endtask

    task check_result_dmem;
        input [31:0]  addr;
        input [31:0]  result;
        input [255:0] test_type;
        begin
            done = 1'b0;
            current_test_id   = current_test_id + 1;
            current_test_type = test_type;
            current_result    = result;

            while (`DMEM_PATH.memory[addr[15:2]] !== result) begin
                current_output = `DMEM_PATH.memory[addr[15:2]];
                @(negedge clk);
            end

            cycle = 0;
            done  = 1'b1;
            $display("[%0d] Test %s passed!", current_test_id, test_type);
        end
    endtask

    initial begin

        rst = 1'b0;
        cycle = 32'b0;
        done = 1'b1;
        current_test_id = 32'b0;
        current_test_type = 256'b0;
        current_output = 32'b0;
        current_result = 32'b0;
        all_tests_passed = 1'b0;

        reset();
        reset_cpu();

        // R-type and shift-immediate tests
        reset();

        RS1 = 5'd1;
        RD1 = -32'sd100;
        RS2 = 5'd2;
        RD2 = 32'd200;
        RD  = 5'd3;
        SHAMT = 5'd20;
        INST_ADDR = 32'h0000_0000;

        `REGFILE_PATH.Registers[RS1] = RD1;
        `REGFILE_PATH.Registers[RS2] = RD2;

        `IMEM_PATH.memory[INST_ADDR + 0]  = {`FNC7_0, RS2,   RS1, `FNC_ADD_SUB, 5'd3,  `OPC_ARI_RTYPE};
        `IMEM_PATH.memory[INST_ADDR + 1]  = {`FNC7_1, RS2,   RS1, `FNC_ADD_SUB, 5'd4,  `OPC_ARI_RTYPE};
        `IMEM_PATH.memory[INST_ADDR + 2]  = {`FNC7_0, RS2,   RS1, `FNC_SLL,     5'd5,  `OPC_ARI_RTYPE};
        `IMEM_PATH.memory[INST_ADDR + 3]  = {`FNC7_0, RS2,   RS1, `FNC_XOR,     5'd8,  `OPC_ARI_RTYPE};
        `IMEM_PATH.memory[INST_ADDR + 4]  = {`FNC7_0, RS2,   RS1, `FNC_OR,      5'd9,  `OPC_ARI_RTYPE};
        `IMEM_PATH.memory[INST_ADDR + 5]  = {`FNC7_0, RS2,   RS1, `FNC_AND,     5'd10, `OPC_ARI_RTYPE};
        `IMEM_PATH.memory[INST_ADDR + 6]  = {`FNC7_0, RS2,   RS1, `FNC_SRL_SRA, 5'd11, `OPC_ARI_RTYPE};
        `IMEM_PATH.memory[INST_ADDR + 7]  = {`FNC7_1, RS2,   RS1, `FNC_SRL_SRA, 5'd12, `OPC_ARI_RTYPE};
        `IMEM_PATH.memory[INST_ADDR + 8]  = {`FNC7_0, SHAMT, RS1, `FNC_SLL,     5'd13, `OPC_ARI_ITYPE};
        `IMEM_PATH.memory[INST_ADDR + 9]  = {`FNC7_0, SHAMT, RS1, `FNC_SRL_SRA, 5'd14, `OPC_ARI_ITYPE};
        `IMEM_PATH.memory[INST_ADDR + 10] = {`FNC7_1, SHAMT, RS1, `FNC_SRL_SRA, 5'd15, `OPC_ARI_ITYPE};

        reset_cpu();

        check_result_rf(5'd3,  32'h0000_0064, "R-Type ADD");
        check_result_rf(5'd4,  32'hffff_fed4, "R-Type SUB");
        check_result_rf(5'd5,  32'hffff_9c00, "R-Type SLL");
        check_result_rf(5'd8,  32'hffff_ff54, "R-Type XOR");
        check_result_rf(5'd9,  32'hffff_ffdc, "R-Type OR");
        check_result_rf(5'd10, 32'h0000_0088, "R-Type AND");
        check_result_rf(5'd11, 32'h00ff_ffff, "R-Type SRL");
        check_result_rf(5'd12, 32'hffff_ffff, "R-Type SRA");
        check_result_rf(5'd13, 32'hf9c0_0000, "I-Type SLLI");
        check_result_rf(5'd14, 32'h0000_0fff, "I-Type SRLI");
        check_result_rf(5'd15, 32'hffff_ffff, "I-Type SRAI");

        // I-type arithmetic tests
        reset();

        RS1 = 5'd1;
        RD1 = -32'sd100;
        IMM = -32'sd200;
        INST_ADDR = 32'h0000_0000;

        `REGFILE_PATH.Registers[RS1] = RD1;

        `IMEM_PATH.memory[INST_ADDR + 0] = {IMM[11:0], RS1, `FNC_ADD_SUB, 5'd3, `OPC_ARI_ITYPE};
        `IMEM_PATH.memory[INST_ADDR + 1] = {IMM[11:0], RS1, `FNC_XOR,     5'd6, `OPC_ARI_ITYPE};
        `IMEM_PATH.memory[INST_ADDR + 2] = {IMM[11:0], RS1, `FNC_OR,      5'd7, `OPC_ARI_ITYPE};
        `IMEM_PATH.memory[INST_ADDR + 3] = {IMM[11:0], RS1, `FNC_AND,     5'd8, `OPC_ARI_ITYPE};

        reset_cpu();

        check_result_rf(5'd3, 32'hffff_fed4, "I-Type ADDI");
        check_result_rf(5'd6, 32'h0000_00a4, "I-Type XORI");
        check_result_rf(5'd7, 32'hffff_ffbc, "I-Type ORI");
        check_result_rf(5'd8, 32'hffff_ff18, "I-Type ANDI");

        // Load word test
        reset();

        `REGFILE_PATH.Registers[1] = 32'h0000_0100;
        IMM0 = 32'h0000_0000;
        INST_ADDR = 32'h0000_0000;
        DATA_ADDR = `REGFILE_PATH.Registers[1] + IMM0[11:0];

        `DMEM_PATH.memory[DATA_ADDR[15:2]] = 32'hdead_beef;
        `IMEM_PATH.memory[INST_ADDR + 0] = {IMM0[11:0], 5'd1, `FNC_LW, 5'd2, `OPC_LOAD};

        reset_cpu();

        check_result_rf(5'd2, 32'hdead_beef, "I-Type LW");

        // Store word test
        reset();

        `REGFILE_PATH.Registers[1] = 32'h1234_5678;
        `REGFILE_PATH.Registers[2] = 32'h0000_0010;
        IMM0 = 32'h0000_0100;
        INST_ADDR = 32'h0000_0000;
        DATA_ADDR0 = `REGFILE_PATH.Registers[2] + IMM0[11:0];

        `IMEM_PATH.memory[INST_ADDR + 0] = {IMM0[11:5], 5'd1, 5'd2, `FNC_SW, IMM0[4:0], `OPC_STORE};
        `DMEM_PATH.memory[DATA_ADDR0[15:2]] = 32'b0;

        reset_cpu();

        check_result_dmem(DATA_ADDR0, 32'h1234_5678, "S-Type SW");

        // LUI test
        reset();

        IMM = 32'h7fff_0123;
        INST_ADDR = 32'h0000_0000;

        `IMEM_PATH.memory[INST_ADDR + 0] = {IMM[31:12], 5'd3, `OPC_LUI};

        reset_cpu();

        check_result_rf(5'd3, 32'h7fff_0000, "U-Type LUI");

        // JAL test
        reset();

        `REGFILE_PATH.Registers[1] = 32'd100;
        `REGFILE_PATH.Registers[2] = 32'd200;
        `REGFILE_PATH.Registers[3] = 32'd300;
        `REGFILE_PATH.Registers[4] = 32'd400;

        IMM = 32'h0000_0ff0;
        INST_ADDR = 32'h0000_0000;
        JUMP_ADDR = 32'h1000_0000 + {IMM[20:1], 1'b0};

        `IMEM_PATH.memory[INST_ADDR + 0]       = {IMM[20], IMM[10:1], IMM[11], IMM[19:12], 5'd5, `OPC_JAL};
        `IMEM_PATH.memory[INST_ADDR + 1]       = {`FNC7_0, 5'd2, 5'd1, `FNC_ADD_SUB, 5'd6, `OPC_ARI_RTYPE};
        `IMEM_PATH.memory[JUMP_ADDR[15:2]]     = {`FNC7_0, 5'd4, 5'd3, `FNC_ADD_SUB, 5'd7, `OPC_ARI_RTYPE};

        reset_cpu();

        check_result_rf(5'd5, 32'h1000_0004, "J-Type JAL link");
        check_result_rf(5'd7, 32'd700,       "J-Type JAL target");
        check_result_rf(5'd6, 32'd0,         "J-Type JAL skip");

        // Branch tests
        IMM = 32'h0000_0ff0;
        INST_ADDR = 32'h0000_0000;
        JUMP_ADDR = 32'h1000_0000 + {19'b0, IMM[12:1], 1'b0};

        BR_TYPE[0] = `FNC_BEQ;
        BR_NAME_TK1[0] = "B-Type BEQ Taken Skip";
        BR_NAME_TK2[0] = "B-Type BEQ Taken Target";
        BR_NAME_NTK[0] = "B-Type BEQ Not Taken";
        BR_TAKEN_OP1[0]  = 32'd100;
        BR_TAKEN_OP2[0]  = 32'd100;
        BR_NTAKEN_OP1[0] = 32'd100;
        BR_NTAKEN_OP2[0] = 32'd200;

        BR_TYPE[1] = `FNC_BNE;
        BR_NAME_TK1[1] = "B-Type BNE Taken Skip";
        BR_NAME_TK2[1] = "B-Type BNE Taken Target";
        BR_NAME_NTK[1] = "B-Type BNE Not Taken";
        BR_TAKEN_OP1[1]  = 32'd100;
        BR_TAKEN_OP2[1]  = 32'd200;
        BR_NTAKEN_OP1[1] = 32'd100;
        BR_NTAKEN_OP2[1] = 32'd100;

        // BEQ taken
        reset();
        `REGFILE_PATH.Registers[1] = BR_TAKEN_OP1[0];
        `REGFILE_PATH.Registers[2] = BR_TAKEN_OP2[0];
        `REGFILE_PATH.Registers[3] = 32'd300;
        `REGFILE_PATH.Registers[4] = 32'd400;

        `IMEM_PATH.memory[INST_ADDR + 0]   = {IMM[12], IMM[10:5], 5'd2, 5'd1, BR_TYPE[0], IMM[4:1], IMM[11], `OPC_BRANCH};
        `IMEM_PATH.memory[INST_ADDR + 1]   = {`FNC7_0, 5'd4, 5'd3, `FNC_ADD_SUB, 5'd5, `OPC_ARI_RTYPE};
        `IMEM_PATH.memory[JUMP_ADDR[15:2]] = {`FNC7_0, 5'd4, 5'd3, `FNC_ADD_SUB, 5'd6, `OPC_ARI_RTYPE};

        reset_cpu();

        check_result_rf(5'd5, 32'd0,   BR_NAME_TK1[0]);
        check_result_rf(5'd6, 32'd700, BR_NAME_TK2[0]);

        // BEQ not taken
        reset();
        `REGFILE_PATH.Registers[1] = BR_NTAKEN_OP1[0];
        `REGFILE_PATH.Registers[2] = BR_NTAKEN_OP2[0];
        `REGFILE_PATH.Registers[3] = 32'd300;
        `REGFILE_PATH.Registers[4] = 32'd400;

        `IMEM_PATH.memory[INST_ADDR + 0] = {IMM[12], IMM[10:5], 5'd2, 5'd1, BR_TYPE[0], IMM[4:1], IMM[11], `OPC_BRANCH};
        `IMEM_PATH.memory[INST_ADDR + 1] = {`FNC7_0, 5'd4, 5'd3, `FNC_ADD_SUB, 5'd5, `OPC_ARI_RTYPE};

        reset_cpu();

        check_result_rf(5'd5, 32'd700, BR_NAME_NTK[0]);

        // BNE taken
        reset();
        `REGFILE_PATH.Registers[1] = BR_TAKEN_OP1[1];
        `REGFILE_PATH.Registers[2] = BR_TAKEN_OP2[1];
        `REGFILE_PATH.Registers[3] = 32'd300;
        `REGFILE_PATH.Registers[4] = 32'd400;

        `IMEM_PATH.memory[INST_ADDR + 0]   = {IMM[12], IMM[10:5], 5'd2, 5'd1, BR_TYPE[1], IMM[4:1], IMM[11], `OPC_BRANCH};
        `IMEM_PATH.memory[INST_ADDR + 1]   = {`FNC7_0, 5'd4, 5'd3, `FNC_ADD_SUB, 5'd5, `OPC_ARI_RTYPE};
        `IMEM_PATH.memory[JUMP_ADDR[15:2]] = {`FNC7_0, 5'd4, 5'd3, `FNC_ADD_SUB, 5'd6, `OPC_ARI_RTYPE};

        reset_cpu();

        check_result_rf(5'd5, 32'd0,   BR_NAME_TK1[1]);
        check_result_rf(5'd6, 32'd700, BR_NAME_TK2[1]);

        // BNE not taken
        reset();
        `REGFILE_PATH.Registers[1] = BR_NTAKEN_OP1[1];
        `REGFILE_PATH.Registers[2] = BR_NTAKEN_OP2[1];
        `REGFILE_PATH.Registers[3] = 32'd300;
        `REGFILE_PATH.Registers[4] = 32'd400;

        `IMEM_PATH.memory[INST_ADDR + 0] = {IMM[12], IMM[10:5], 5'd2, 5'd1, BR_TYPE[1], IMM[4:1], IMM[11], `OPC_BRANCH};
        `IMEM_PATH.memory[INST_ADDR + 1] = {`FNC7_0, 5'd4, 5'd3, `FNC_ADD_SUB, 5'd5, `OPC_ARI_RTYPE};

        reset_cpu();

        check_result_rf(5'd5, 32'd700, BR_NAME_NTK[1]);

        all_tests_passed = 1'b1;

        repeat (20) @(posedge clk);
        $display("All tests passed!");
        $finish();
    end

endmodule
