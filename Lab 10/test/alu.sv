module alu (
    
    input  logic [31:0] operand1,
    input  logic [31:0] operand2,
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
        // 1001 : PASS_B   used for LUI

        case (alu_operation)

            4'b0000: begin
                result = operand1 + operand2;                                  // ADD
            end

            4'b1111: begin
                result = operand1 - operand2;                                  // SUB
            end

            4'b0001: begin
                result = operand1 ^ operand2;                                  // XOR
            end

            4'b0010: begin
                result = operand1 | operand2;                                  // OR
            end

            4'b0011: begin
                result = operand1 & operand2;                                  // AND
            end

            4'b0100: begin
                result = {31'b0, ($signed(operand1) < $signed(operand2))};     // SLT
            end

            4'b0101: begin
                result = operand1 << operand2[4:0];                            // SLL
            end

            4'b0110: begin
                result = {31'b0, ($unsigned(operand1) < $unsigned(operand2))}; // SLTU
            end

            4'b0111: begin
                result = operand1 >> operand2[4:0];                            // SRL
            end

            4'b1000: begin
                result = $signed(operand1) >>> operand2[4:0];                  // SRA
            end

            4'b1001: begin
                result = operand2;                                             // PASS_B for LUI
            end

            default: begin
                result = 32'b0;
            end

        endcase

    end

    // Zero flag is high whenever ALU output is zero
    assign zero = (result == 32'b0);

endmodule