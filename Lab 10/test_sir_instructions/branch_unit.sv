// Include for MACROS
`include "opcode.vh"


module branch_unit(
    input  logic [31:0] rs1_data,
    input  logic [31:0] rs2_data,
    input  logic [2:0]  br_type,
    input  logic        br_en,
    output logic        br_taken
    );

    // Custom branch type for JAL.
    localparam logic [2:0] BR_JAL = 3'b010;


    always_comb begin

        // Default value
        br_taken = 1'b0;

        if (br_en) begin

            case (br_type)

                // BEQ: branch if rs1 == rs2
                `FNC_BEQ: begin
                    br_taken = (rs1_data == rs2_data);
                end

                // BNE: branch if rs1 != rs2
                `FNC_BNE: begin
                    br_taken = (rs1_data != rs2_data);
                end

                // JAL: unconditional jump
                BR_JAL: begin
                    br_taken = 1'b1;
                end

                // Other branch types are not implemented in this lab
                default: begin
                    br_taken = 1'b0;
                end

            endcase

        end

    end

endmodule