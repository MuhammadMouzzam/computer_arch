`timescale 1ns/1ps

`include "mem_path.vh"


module cpu_wave_load_tb;

    logic clk;
    logic rst;

    integer i;


    cpu cpu (
        .clk (clk),
        .rst (rst)
    );


    // Clock generation
    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end


    // Short reset for clean waveform
    task reset_cpu;
        begin
            rst = 1'b1;
            @(posedge clk);
            #1;
            rst = 1'b0;
        end
    endtask


    // Clear memories and register file
    task clear_all;
        begin

            for (i = 0; i < 32; i = i + 1) begin
                `REGFILE_PATH.Registers[i] = 32'b0;
            end

            for (i = 0; i < 512; i = i + 1) begin
                `DMEM_PATH.memory[i] = 32'b0;
            end

            for (i = 0; i < 16384; i = i + 1) begin
                `IMEM_PATH.memory[i] = 32'h0000_0013; // nop
            end

        end
    endtask


    // Load only one lw instruction
    task load_program;
        begin

            // Data at byte address 0
            `DMEM_PATH.memory[0] = 32'd5;

            // Program starts at PC = 32'h1000_0000
            `IMEM_PATH.memory[0] = 32'h0000_2083; // lw x1, 0(x0)
            `IMEM_PATH.memory[1] = 32'h0000_0013; // nop
            `IMEM_PATH.memory[2] = 32'h0000_0013; // nop

        end
    endtask


    initial begin

        rst = 1'b0;

        clear_all();
        load_program();

        reset_cpu();

        repeat (4) begin
            @(negedge clk);

            $display("time=%0t PC=%h instr=%h rdata=%0d wr_data=%0d x1=%0d",
                     $time,
                     cpu.pc_curr,
                     cpu.instr,
                     cpu.rdata,
                     cpu.wr_data,
                     `REGFILE_PATH.Registers[1]);
        end

        $display("Final x1 = %0d", `REGFILE_PATH.Registers[1]);

        $stop;

    end

endmodule