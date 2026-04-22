module data_mem
#(
    parameter int unsigned DEPTH = 256,
    parameter string       INIT_FILE = ""
)
(
    input  logic        clk,
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [2:0]  funct3,
    input  logic [31:0] addr,
    input  logic [31:0] write_data,
    output logic [31:0] read_data,
    output logic        misaligned
);

    localparam int unsigned ADDR_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH);

    logic [31:0] mem [0:DEPTH-1];
    logic [ADDR_W-1:0] word_addr;
    logic [31:0] word_rdata;
    logic [31:0] write_word_next;
    logic [7:0]  sel_byte;
    logic [15:0] sel_half;
    integer i;

    assign word_addr = addr[ADDR_W+1:2];

    initial begin
        for (i = 0; i < DEPTH; i++) begin
            mem[i] = 32'b0;
        end

        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    always_comb begin
        if (word_addr < DEPTH) begin
            word_rdata = mem[word_addr];
        end
        else begin
            word_rdata = 32'b0;
        end
    end

    always_comb begin
        // Defaults
        read_data       = 32'b0;
        write_word_next = word_rdata;
        misaligned      = 1'b0;
        sel_byte        = 8'b0;
        sel_half        = 16'b0;

        // Byte select inside the fetched word
        case (addr[1:0])
            2'b00: sel_byte = word_rdata[7:0];
            2'b01: sel_byte = word_rdata[15:8];
            2'b10: sel_byte = word_rdata[23:16];
            2'b11: sel_byte = word_rdata[31:24];
            default: sel_byte = 8'b0;
        endcase

        // Halfword select inside the fetched word
        case (addr[1])
            1'b0: sel_half = word_rdata[15:0];
            1'b1: sel_half = word_rdata[31:16];
            default: sel_half = 16'b0;
        endcase

        // Alignment checks
        if (mem_read || mem_write) begin
            case (funct3)
                3'b001, // LH / SH
                3'b101: // LHU
                    misaligned = addr[0];
                3'b010: // LW / SW
                    misaligned = |addr[1:0];
                default:
                    misaligned = 1'b0;
            endcase
        end

        // Read path
        if (mem_read && !misaligned) begin
            case (funct3)
                3'b000: read_data = {{24{sel_byte[7]}}, sel_byte}; // LB
                3'b001: read_data = {{16{sel_half[15]}}, sel_half}; // LH
                3'b010: read_data = word_rdata; // LW
                3'b100: read_data = {24'b0, sel_byte}; // LBU
                3'b101: read_data = {16'b0, sel_half}; // LHU
                default: read_data = 32'b0;
            endcase
        end

        // Write path (word update prepared here, committed on clock edge)
        if (mem_write && !misaligned) begin
            case (funct3)
                3'b000: begin // SB
                    case (addr[1:0])
                        2'b00: write_word_next[7:0]   = write_data[7:0];
                        2'b01: write_word_next[15:8]  = write_data[7:0];
                        2'b10: write_word_next[23:16] = write_data[7:0];
                        2'b11: write_word_next[31:24] = write_data[7:0];
                        default: ;
                    endcase
                end

                3'b001: begin // SH
                    if (addr[1] == 1'b0) begin
                        write_word_next[15:0] = write_data[15:0];
                    end
                    else begin
                        write_word_next[31:16] = write_data[15:0];
                    end
                end

                3'b010: begin // SW
                    write_word_next = write_data;
                end

                default: ;
            endcase
        end
    end

    always @(posedge clk) begin
        if (mem_write && !misaligned && (word_addr < DEPTH)) begin
            mem[word_addr] <= write_word_next;
        end
    end

endmodule