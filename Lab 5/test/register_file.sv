module register_file
#(
    parameter int unsigned XLEN      = 32,
    parameter int unsigned REG_COUNT = 32
)
(
    input  logic                         clk,
    input  logic                         rst,
    input  logic                         RegWrite,

    input  logic [$clog2(REG_COUNT)-1:0] rs1_addr,
    input  logic [$clog2(REG_COUNT)-1:0] rs2_addr,
    input  logic [$clog2(REG_COUNT)-1:0] rd_addr,

    input  logic [XLEN-1:0]              wr_data,

    output logic [XLEN-1:0]              rs1_data,
    output logic [XLEN-1:0]              rs2_data
);

    // Name kept as "Registers" to match mycpu_tb.sv
    logic [XLEN-1:0] Registers [0:REG_COUNT-1];

    integer i;


    // Initialize at start
    initial begin
        for (i = 0; i < REG_COUNT; i = i + 1) begin
            Registers[i] = '0;
        end
    end


    // Synchronous write
    // Do not clear Registers on rst because mycpu_tb writes register values before calling reset_cpu().
    always @(posedge clk) begin

        if (RegWrite && (rd_addr != '0)) begin
            Registers[rd_addr] <= wr_data;
        end

        Registers[0] <= '0;

    end


    // Asynchronous read
    always_comb begin

        if (rs1_addr == '0) begin
            rs1_data = '0;
        end
        else begin
            rs1_data = Registers[rs1_addr];
        end

        if (rs2_addr == '0) begin
            rs2_data = '0;
        end
        else begin
            rs2_data = Registers[rs2_addr];
        end

    end

endmodule