module insertion_sort_top
(
    input  logic clk,
    input  logic reset,

    output logic an0,
    output logic an1,
    output logic an2,
    output logic an3,
    output logic an4,
    output logic an5,
    output logic an6,
    output logic an7,

    output logic segA,
    output logic segB,
    output logic segC,
    output logic segD,
    output logic segE,
    output logic segF,
    output logic segG
);

    logic [31:0] array0;
    logic [31:0] array1;
    logic [31:0] array2;
    logic [31:0] array3;

    logic [3:0] num [7:0];


    cpu
    #(
        .RESET_PC   (32'h1000_0000),
        .IMEM_DEPTH (64),
        .DMEM_DEPTH (64),
        .IMEM_FILE  (""),
        .DMEM_FILE  ("")
    )
    CPU_INST
    (
        .clk    (clk),
        .rst    (reset),

        .array0 (array0),
        .array1 (array1),
        .array2 (array2),
        .array3 (array3)
    );


    // Send array values to seven-segment display
    assign num[0] = array0[3:0];
    assign num[1] = array1[3:0];
    assign num[2] = array2[3:0];
    assign num[3] = array3[3:0];

    // Unused digits kept at zero
    assign num[4] = 4'h0;
    assign num[5] = 4'h0;
    assign num[6] = 4'h0;
    assign num[7] = 4'h0;


    sim_dis DISPLAY_INST
    (
        .num   (num),
        .reset (reset),
        .clk   (clk),

        .an0   (an0),
        .an1   (an1),
        .an2   (an2),
        .an3   (an3),
        .an4   (an4),
        .an5   (an5),
        .an6   (an6),
        .an7   (an7),

        .segA  (segA),
        .segB  (segB),
        .segC  (segC),
        .segD  (segD),
        .segE  (segE),
        .segF  (segF),
        .segG  (segG)
    );

endmodule