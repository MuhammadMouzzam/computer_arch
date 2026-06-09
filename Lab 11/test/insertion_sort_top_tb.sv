`timescale 1ns/1ps

module insertion_sort_top_tb;

    logic clk;
    logic reset;

    logic an0;
    logic an1;
    logic an2;
    logic an3;
    logic an4;
    logic an5;
    logic an6;
    logic an7;

    logic segA;
    logic segB;
    logic segC;
    logic segD;
    logic segE;
    logic segF;
    logic segG;


    insertion_sort_top dut
    (
        .clk   (clk),
        .reset (reset),

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


    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;   // 100 MHz clock
    end


    task automatic print_values(input string label);

        begin

            $display("");
            $display("============================================================");
            $display("%s", label);
            $display("============================================================");

            $display("Data memory array values:");
            $display("array0 = %0d", dut.array0);
            $display("array1 = %0d", dut.array1);
            $display("array2 = %0d", dut.array2);
            $display("array3 = %0d", dut.array3);

            $display("");
            $display("Values connected to seven-segment display:");
            $display("num[0] = %0d", dut.num[0]);
            $display("num[1] = %0d", dut.num[1]);
            $display("num[2] = %0d", dut.num[2]);
            $display("num[3] = %0d", dut.num[3]);
            $display("num[4] = %0d", dut.num[4]);
            $display("num[5] = %0d", dut.num[5]);
            $display("num[6] = %0d", dut.num[6]);
            $display("num[7] = %0d", dut.num[7]);

        end

    endtask


    initial begin

        reset = 1'b1;

        #20;

        print_values("INITIAL VALUES BEFORE SORTING");

        repeat (5) @(posedge clk);
        reset = 1'b0;

        repeat (300) @(posedge clk);

        #10;

        print_values("FINAL VALUES AFTER SORTING");

        $finish;

    end

endmodule