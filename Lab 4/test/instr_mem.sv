module instr_mem
#(
    parameter int unsigned DEPTH = 256,
    parameter string       INIT_FILE = ""
)
(
    input  logic [31:0] addr,
    output logic [31:0] instr
);

    localparam int unsigned ADDR_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH);

    logic [31:0] mem [0:DEPTH-1];
    logic [ADDR_W-1:0] word_addr;
    integer i;

    assign word_addr = addr[ADDR_W+1:2];

    initial begin
        for (i = 0; i < DEPTH; i++) begin
            mem[i] = 32'h0000_0013; // NOP = addi x0, x0, 0
        end

        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end

        // Optional hardcoded program example:
        // mem[0] = 32'h00500093; // addi x1, x0, 5
        // mem[1] = 32'h00A00113; // addi x2, x0, 10
        // mem[2] = 32'h002081B3; // add  x3, x1, x2
    end

    always_comb begin
        if ((addr[1:0] != 2'b00) || (word_addr >= DEPTH)) begin
            instr = 32'h0000_0013; // safe NOP on bad fetch
        end
        else begin
            instr = mem[word_addr];
        end
    end

endmodule