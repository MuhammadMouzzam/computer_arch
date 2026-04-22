module pc
#(parameter logic [31:0] RESET_PC = 32'h0000_0000)
(
    input  logic        clk,
    input  logic        rst,
    input  logic        pc_we,
    input  logic [31:0] pc_next,
    output logic [31:0] pc_curr
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_curr <= RESET_PC;
        end
        else if (pc_we) begin
            pc_curr <= pc_next;
        end
    end

endmodule