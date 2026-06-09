module instr_mem
#(
    parameter int unsigned DEPTH = 16384, // EECS151 section 4.5.2
    parameter string       INIT_FILE = ""
)
(
    input  logic [31:0] addr,
    output logic [31:0] instr
);

    localparam int unsigned ADDR_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH);

    // Named "memory" to match mycpu_tb.sv
    logic [31:0] memory [0:DEPTH-1];

    logic [ADDR_W-1:0] word_addr;

    integer i;


    // Instruction memory is word-addressed.
    assign word_addr = addr[ADDR_W+1:2];

    initial begin

        // Initialize instruction memory with NOPs
        for (i = 0; i < DEPTH; i = i + 1) begin
            memory[i] = 32'h0000_0013; // NOP = addi x0, x0, 0
        end

        // Optional hex-file initialization
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, memory);
        end

    end

    always_comb begin

        // If PC is not word-aligned, output safe NOP
        if (addr[1:0] != 2'b00) begin
            instr = 32'h0000_0013; // NOP
        end

        else begin
            instr = memory[word_addr];
        end

    end

endmodule