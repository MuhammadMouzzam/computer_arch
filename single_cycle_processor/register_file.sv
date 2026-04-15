module register_file
#(
    parameter int unsigned XLEN      = 32,
    parameter int unsigned REG_COUNT = 32
)
(
    input  logic                             clk,
    input  logic                             rst,
    input  logic                             we,
    input  logic [$clog2(REG_COUNT)-1:0]     rs1_addr,
    input  logic [$clog2(REG_COUNT)-1:0]     rs2_addr,
    input  logic [$clog2(REG_COUNT)-1:0]     rd_addr,
    input  logic [XLEN-1:0]                  wr_data,
    output logic [XLEN-1:0]                  rs1_data,
    output logic [XLEN-1:0]                  rs2_data
);

    logic [XLEN-1:0] regs [0:REG_COUNT-1];
    integer i;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < REG_COUNT; i++) begin
                regs[i] <= '0;
            end
        end
        else begin
            if (we && (rd_addr != '0)) begin
                regs[rd_addr] <= wr_data;
            end

            regs[0] <= '0; // x0 is always zero
        end
    end

    always_comb begin
        // Read port 1
        if (rs1_addr == '0) begin
            rs1_data = '0;
        end
        else if (we && (rd_addr == rs1_addr) && (rd_addr != '0)) begin
            rs1_data = wr_data; // simple same-cycle bypass
        end
        else begin
            rs1_data = regs[rs1_addr];
        end

        // Read port 2
        if (rs2_addr == '0) begin
            rs2_data = '0;
        end
        else if (we && (rd_addr == rs2_addr) && (rd_addr != '0)) begin
            rs2_data = wr_data; // simple same-cycle bypass
        end
        else begin
            rs2_data = regs[rs2_addr];
        end
    end

endmodule