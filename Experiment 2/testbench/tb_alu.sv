`timescale 1ns/1ps

module alu_tb;

    // DUT signals
    logic [31:0] operand1, operand2;
    logic [3:0]  alu_operation;
    logic [31:0] result;
    logic        zero;

    // Instantiate DUT
    alu alu_inst (
        .operand1      (operand1),
        .operand2      (operand2),
        .alu_operation (alu_operation),
        .result        (result),
        .zero          (zero)
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


    // Benchmark for result
    function automatic logic [31:0] expected_result(input logic [31:0] a,input logic [31:0] b, input logic [3:0]  op);

        case (op)

            // Generate actual result of operands and alu_operation
            ALU_ADD  : expected_result = a + b;
            ALU_SUB  : expected_result = a - b;
            ALU_XOR  : expected_result = a ^ b;
            ALU_OR   : expected_result = a | b;
            ALU_AND  : expected_result = a & b;
            ALU_SLT  : expected_result = {31'b0, ($signed(a) < $signed(b))};
            ALU_SLL  : expected_result = a << b[4:0];
            ALU_SLTU : expected_result = {31'b0, ($unsigned(a) < $unsigned(b))};
            ALU_SRL  : expected_result = a >> b[4:0];
            ALU_SRA  : expected_result = $signed(a) >>> b[4:0];
            default  : expected_result = 32'b0;

        endcase

    endfunction

    // Benchmark for zero flag
    function automatic logic expected_zero(input logic [31:0] a, input logic [31:0] b, input logic [3:0]  op);

        logic [31:0] temp_result;

        begin

            // Generate actual result for operands and alu_operation
            temp_result = expected_result(a, b, op);

            // Generate actual zero flag
            expected_zero = (op == ALU_SUB) && (temp_result == 32'b0);

        end

    endfunction

    // Helper function to print alu_operation name
    function automatic string op_name(input logic [3:0] op);


        case (op)

            ALU_ADD  : op_name = "ADD";
            ALU_SUB  : op_name = "SUB";
            ALU_XOR  : op_name = "XOR";
            ALU_OR   : op_name = "OR";
            ALU_AND  : op_name = "AND";
            ALU_SLT  : op_name = "SLT";
            ALU_SLL  : op_name = "SLL";
            ALU_SLTU : op_name = "SLTU";
            ALU_SRL  : op_name = "SRL";
            ALU_SRA  : op_name = "SRA";
            default  : op_name = "UNKNOWN";

        endcase
        
    endfunction

    // Task to run a single test
    task automatic run_test(input logic [31:0] a, input logic [31:0] b, input logic [3:0]  op);

        logic [31:0] actual_result;
        logic        actual_zero_flag;

        begin
            operand1       = a;
            operand2       = b;
            alu_operation  = op;

            // Small delay to settle
            #1;

            // Get benchmarks
            actual_result      = expected_result(a, b, op);
            actual_zero_flag   = expected_zero(a, b, op);

            // Update number or tests done
            total_tests++;

            // Check if result or zero flag do not match
            if ((result !== actual_result) || (zero !== actual_zero_flag)) begin

                // Update number of failed tests
                failed_tests++;

                $display("FAIL | op=%s | operand1=0x%08h | operand2=0x%08h | result=0x%08h | actual_result=0x%08h | zero=%0b | actual_zero_flag=%0b",
                         op_name(op), a, b, result, actual_result, zero, actual_zero_flag);
            end

            else begin

                // Otherwise update number of passed tests
                passed_tests++;

            end
        end

    endtask

    // Random alu_operation generator
    function automatic logic [3:0] random_alu_operation();

        int sel;
        begin

            // Generate a random number for 10 alu_operations
            sel = $urandom_range(9, 0);

            case (sel)

                0: random_alu_operation       = ALU_ADD;
                1: random_alu_operation       = ALU_SUB;
                2: random_alu_operation       = ALU_XOR;
                3: random_alu_operation       = ALU_OR;
                4: random_alu_operation       = ALU_AND;
                5: random_alu_operation       = ALU_SLT;
                6: random_alu_operation       = ALU_SLL;
                7: random_alu_operation       = ALU_SLTU;
                8: random_alu_operation       = ALU_SRL;
                9: random_alu_operation       = ALU_SRA;
                default: random_alu_operation = ALU_ADD;

            endcase
        end

    endfunction

    // Begin testing
    initial begin

        $display("Testting ALU");

        // Initialize inputs
        operand1      = 32'b0;
        operand2      = 32'b0;
        alu_operation = ALU_ADD;
        #5;

        // Corner tests
        run_test(32'h00000000, 32'h00000000, ALU_ADD);  //ADD zero
        run_test(32'hFFFFFFFF, 32'h00000001, ALU_ADD);   //ADD wrap
        run_test(32'h12345678, 32'h12345678, ALU_SUB);   //SUB zero
        run_test(32'h80000000, 32'h00000001, ALU_SLT);   //SLT signed
        run_test(32'h00000001, 32'hFFFFFFFF, ALU_SLTU);  //SLTU unsigned
        run_test(32'h80000000, 32'h0000001F, ALU_SRL);   //SRL max shift
        run_test(32'h80000000, 32'h0000001F, ALU_SRA);   //SRA max shift

        // Random testing
        repeat (5000) begin

            run_test($urandom, $urandom, random_alu_operation());

        end

        // Display summary
        $display("ALU Testing Finished");
        $display("Total Tests  : %0d", total_tests);
        $display("Passed Tests : %0d", passed_tests);
        $display("Failed Tests : %0d", failed_tests);

        if (failed_tests == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule