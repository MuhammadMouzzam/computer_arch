// Include for MACROS
`include "opcode.vh"


module data_mem
#(
    parameter int unsigned DEPTH = 16384,
    parameter string       INIT_FILE = ""
)
(
    input  logic        clk,

    input  logic        MemRead,
    input  logic        MemWrite,
    input  logic [2:0]  funct3,

    input  logic [31:0] addr,
    input  logic [31:0] wdata,

    output logic [31:0] rdata
);

    localparam int unsigned ADDR_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH);

    // Name kept as "memory" to match mycpu_tb.sv
    logic [31:0] memory [0:DEPTH-1];

    logic [ADDR_W-1:0] word_addr;
    logic [31:0]       word_rdata;
    logic [31:0]       write_word_next;

    logic [7:0]        sel_byte;
    logic [15:0]       sel_half;
    logic              misaligned;

    integer i;


    // Data memory is word-addressed.
    assign word_addr = addr[ADDR_W+1:2];


    initial begin

        for (i = 0; i < DEPTH; i = i + 1) begin
            memory[i] = 32'b0;
        end

        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, memory);
        end

    end


    // Asynchronous word read
    always_comb begin

        if (word_addr < DEPTH) begin
            word_rdata = memory[word_addr];
        end

        else begin
            word_rdata = 32'b0;
        end

    end


    // Read formatting, write-data preparation, and alignment check
    always_comb begin

        // Defaults
        rdata           = 32'b0;
        write_word_next = word_rdata;
        misaligned      = 1'b0;
        sel_byte        = 8'b0;
        sel_half        = 16'b0;


        // Select byte from word, little-endian
        case (addr[1:0])

            2'b00: begin
                sel_byte = word_rdata[7:0];
            end

            2'b01: begin
                sel_byte = word_rdata[15:8];
            end

            2'b10: begin
                sel_byte = word_rdata[23:16];
            end

            2'b11: begin
                sel_byte = word_rdata[31:24];
            end

            default: begin
                sel_byte = 8'b0;
            end

        endcase


        // Select halfword from word, little-endian
        case (addr[1])

            1'b0: begin
                sel_half = word_rdata[15:0];
            end

            1'b1: begin
                sel_half = word_rdata[31:16];
            end

            default: begin
                sel_half = 16'b0;
            end

        endcase


        // Alignment check
        if (MemRead || MemWrite) begin

            case (funct3)

                `FNC_LH,
                `FNC_LHU: begin
                    misaligned = addr[0];
                end

                `FNC_LW: begin
                    misaligned = |addr[1:0];
                end

                default: begin
                    misaligned = 1'b0;
                end

            endcase

        end


        // Read path
        if (MemRead && !misaligned) begin

            case (funct3)

                `FNC_LB: begin
                    rdata = {{24{sel_byte[7]}}, sel_byte};
                end

                `FNC_LH: begin
                    rdata = {{16{sel_half[15]}}, sel_half};
                end

                `FNC_LW: begin
                    rdata = word_rdata;
                end

                `FNC_LBU: begin
                    rdata = {24'b0, sel_byte};
                end

                `FNC_LHU: begin
                    rdata = {16'b0, sel_half};
                end

                default: begin
                    rdata = 32'b0;
                end

            endcase

        end


        // Write path preparation
        if (MemWrite && !misaligned) begin

            case (funct3)

                `FNC_SB: begin

                    case (addr[1:0])

                        2'b00: begin
                            write_word_next[7:0] = wdata[7:0];
                        end

                        2'b01: begin
                            write_word_next[15:8] = wdata[7:0];
                        end

                        2'b10: begin
                            write_word_next[23:16] = wdata[7:0];
                        end

                        2'b11: begin
                            write_word_next[31:24] = wdata[7:0];
                        end

                        default: begin
                            write_word_next = word_rdata;
                        end

                    endcase

                end


                `FNC_SH: begin

                    if (addr[1] == 1'b0) begin
                        write_word_next[15:0] = wdata[15:0];
                    end

                    else begin
                        write_word_next[31:16] = wdata[15:0];
                    end

                end


                `FNC_SW: begin
                    write_word_next = wdata;
                end


                default: begin
                    write_word_next = word_rdata;
                end

            endcase

        end

    end


    // Synchronous write
    always @(posedge clk) begin

        if (MemWrite && !misaligned && (word_addr < DEPTH)) begin
            memory[word_addr] <= write_word_next;
        end

    end

endmodule