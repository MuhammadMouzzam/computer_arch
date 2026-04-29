`include "opcode.vh"

module immediate_generator (
    input  logic [31:0] instr,
    output logic [31:0] immediate
);

    logic [6:0] opcode;

    assign opcode = instr[6:0];

    always_comb begin

        case (opcode)

            // I-type immediate:
            // load, jalr, arithmetic immediate
            `OPC_LOAD,
            `OPC_JALR,
            `OPC_ARI_ITYPE,
            `OPC_CSR: begin

                immediate = {{20{instr[31]}}, instr[31:20]};

            end


            // S-type immediate:
            // store
            `OPC_STORE: begin

                immediate = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            end


            // B-type immediate:
            // branch target offset
            // imm = SignExt({instr[31], instr[7], instr[30:25], instr[11:8], 1'b0})
            `OPC_BRANCH: begin

                immediate = {{19{instr[31]}},
                             instr[31],
                             instr[7],
                             instr[30:25],
                             instr[11:8],
                             1'b0};

            end


            // U-type immediate:
            // lui, auipc
            `OPC_LUI,
            `OPC_AUIPC: begin

                immediate = {instr[31:12], 12'b0};

            end


            // J-type immediate:
            // jal target offset
            // imm = SignExt({instr[31], instr[19:12], instr[20], instr[30:21], 1'b0})
            `OPC_JAL: begin

                immediate = {{11{instr[31]}},
                             instr[31],
                             instr[19:12],
                             instr[20],
                             instr[30:21],
                             1'b0};

            end


            // Default safe assignment
            default: begin

                immediate = 32'b0;

            end

        endcase

    end

endmodule