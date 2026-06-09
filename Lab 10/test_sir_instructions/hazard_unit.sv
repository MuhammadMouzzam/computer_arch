module hazard_unit
(
    input  logic [4:0] rs1_addr,
    input  logic [4:0] rs2_addr,
    input  logic [4:0] dx_mw_rd_addr,
    input  logic       dx_mw_RegWrite,

    output logic       forward_rs1,
    output logic       forward_rs2
);

    always_comb begin

        forward_rs1 = 1'b0;
        forward_rs2 = 1'b0;

        if (dx_mw_RegWrite && (dx_mw_rd_addr != 5'b0)) begin

            if (dx_mw_rd_addr == rs1_addr) begin
                forward_rs1 = 1'b1;
            end

            if (dx_mw_rd_addr == rs2_addr) begin
                forward_rs2 = 1'b1;
            end

        end

    end

endmodule