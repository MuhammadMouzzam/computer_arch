module alu (
    input  logic [31:0] operand1, operand2,
    input  logic [3:0]  alu_operation,
    output logic [31:0] result,
    output logic        zero
);

    always_comb begin
        // alu_operation encoding:
        // 0000 : ADD
        // 1111 : SUB
        // 0001 : XOR
        // 0010 : OR
        // 0011 : AND
        // 0100 : SLT
        // 0101 : SLL
        // 0110 : SLTU
        // 0111 : SRL
        // 1000 : SRA

        case (alu_operation)
            4'b0000: result = operand1 + operand2;                                  // ADD
            4'b1111: result = operand1 - operand2;                                  // SUB
            4'b0001: result = operand1 ^ operand2;                                  // XOR
            4'b0010: result = operand1 | operand2;                                  // OR
            4'b0011: result = operand1 & operand2;                                  // AND
            4'b0100: result = {31'b0, ($signed(operand1) < $signed(operand2))};     // SLT
            4'b0101: result = operand1 << operand2[4:0];                            // SLL
            4'b0110: result = {31'b0, ($unsigned(operand1) < $unsigned(operand2))}; // SLTU
            4'b0111: result = operand1 >> operand2[4:0];                            // SRL
            4'b1000: result = $signed(operand1) >>> operand2[4:0];                  // SRA
            default: result = 32'b0;
        endcase
    end

    // zero flag asserted when result of subtraction is zero
    assign zero = (alu_operation == 4'b1111) && (result == 32'b0);

endmodule