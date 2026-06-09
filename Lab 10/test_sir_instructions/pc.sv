module pc
#(
    // Match mycpu_tb.sv
    parameter logic [31:0] RESET_PC = 32'h1000_0000
)
(
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] pc_next,
    output logic [31:0] pc_curr
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_curr <= RESET_PC;
        end
        else begin
            pc_curr <= pc_next;
        end
    end

endmodule