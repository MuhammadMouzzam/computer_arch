module instr_mem
#(
    parameter int unsigned DEPTH = 64, // enough for 29 insertion-sort instructions
    parameter string       INIT_FILE = ""
)

(
    input  logic [31:0] addr,
    output logic [31:0] instr
);

    localparam int unsigned ADDR_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH);

    // CHANGE: distributed memory style added for FPGA LUT/distributed RAM inference
    (* ram_style = "distributed" *) logic [31:0] memory [0:DEPTH-1];

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

        // CHANGE: insertion sort program loaded directly into instruction memory.Total 29 instructions.
        memory[0]  = 32'h00000093; // addi x1, x0, 0        
        memory[1]  = 32'h00400113; // addi x2, x0, 4       
        memory[2]  = 32'h00100193; // addi x3, x0, 1        

        memory[3]  = 32'h0021a433; // slt  x8, x3, x2       
        memory[4]  = 32'h06040063; // beq  x8, x0, done     
        memory[5]  = 32'h00219313; // slli x6, x3, 2        
        memory[6]  = 32'h00608333; // add  x6, x1, x6       
        memory[7]  = 32'h00032283; // lw   x5, 0(x6)        
        memory[8]  = 32'hfff18213; // addi x4, x3, -1       

        memory[9]  = 32'h00022433; // slt  x8, x4, x0       
        memory[10] = 32'h02041863; // bne  x8, x0, insert   
        memory[11] = 32'h00221313; // slli x6, x4, 2        
        memory[12] = 32'h00608333; // add  x6, x1, x6       
        memory[13] = 32'h00032383; // lw   x7, 0(x6)        
        memory[14] = 32'h0072a433; // slt  x8, x5, x7       
        memory[15] = 32'h00040e63; // beq  x8, x0, insert   

        memory[16] = 32'h00120513; // addi x10, x4, 1       
        memory[17] = 32'h00251593; // slli x11, x10, 2      
        memory[18] = 32'h00b085b3; // add  x11, x1, x11     
        memory[19] = 32'h0075a023; // sw   x7, 0(x11)       
        memory[20] = 32'hfff20213; // addi x4, x4, -1       
        memory[21] = 32'hfd1ff06f; // jal  x0, while_loop   

        memory[22] = 32'h00120513; // addi x10, x4, 1       
        memory[23] = 32'h00251593; // slli x11, x10, 2      
        memory[24] = 32'h00b085b3; // add  x11, x1, x11     
        memory[25] = 32'h0055a023; // sw   x5, 0(x11)       
        memory[26] = 32'h00118193; // addi x3, x3, 1        
        memory[27] = 32'hfa1ff06f; // jal  x0, for_loop     

        memory[28] = 32'h0000006f; // jal  x0, done       

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