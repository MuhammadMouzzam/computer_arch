`timescale 1ns/1ps

 module sim_dis (
        input  logic [3:0] num [7:0],
        input  logic reset, clk,
        output logic an0, an1, an2, an3, an4, an5, an6, an7,
        output logic segA, segB, segC, segD, segE, segF, segG);

logic en0, en1, en2, en3, en4, en5, en6, en7, count_en, clk1;
logic [3:0] q0, q1, q2, q3, q4, q5, q6, q7;
//logic A, B, C;
logic [2:0] count_d, count_q; //2-bit counter


//logic [3:0] num [7:0] = {4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8};

clk_delay_display CLK_DELAY_DISP 
(
    .clk(clk),
    .reset(reset),
    .clk_out(clk1)
);

assign count_en = 1;

//COUNTER
always_comb count_d = count_q + 1;
always_ff@(posedge clk1 or posedge reset)
begin
    if (reset) begin
        count_q <= #1 0;
    end
    else if (count_en) begin
        count_q <= #1 count_d;
    end
end

//MUX1
logic [3:0] y;
always_comb begin
    case (count_q)
        3'b000:y = num[0];
        3'b001:y = num[1];
        3'b010:y = num[2];
        3'b011:y = num[3];
        3'b100:y = num[4];
        3'b101:y = num[5];
        3'b110:y = num[6];
        3'b111:y = num[7];
    endcase
end

//DECODER FOR CATHODE
logic [6:0] s;
always_comb
begin
    segA = s[6];
    segB = s[5];
    segC = s[4];
    segD = s[3];
    segE = s[2];
    segF = s[1];
    segG = s[0];
end

always_comb begin
    case (y)
        4'b0000: s = 7'b000_0001;
        4'b0001: s = 7'b100_1111;
        4'b0010: s = 7'b001_0010;
        4'b0011: s = 7'b000_0110;
        4'b0100: s = 7'b100_1100;
        4'b0101: s = 7'b010_0100;
        4'b0110: s = 7'b010_0000;
        4'b0111: s = 7'b000_1111;
        4'b1000: s = 7'b000_0000;
        4'b1001: s = 7'b000_0100;
        4'b1010: s = 7'b000_1000;
        4'b1011: s = 7'b110_0000;
        4'b1100: s = 7'b011_0001;
        4'b1101: s = 7'b100_0010;
        4'b1110: s = 7'b011_0000;
        4'b1111: s = 7'b011_1000;
    endcase
end


//DECODER FOR ANODE
logic [7:0] z;
always_comb
begin
    an0 = z[7];
    an1 = z[6];
    an2 = z[5];
    an3 = z[4];
    an4 = z[3];
    an5 = z[2];
    an6 = z[1];
    an7 = z[0];
end

always_comb begin
    case (count_q)
        3'b000: z = 8'b01111111;
        3'b001: z = 8'b10111111;
        3'b010: z = 8'b11011111;
        3'b011: z = 8'b11101111;
        3'b100: z = 8'b11110111;
        3'b101: z = 8'b11111011;
        3'b110: z = 8'b11111101;
        3'b111: z = 8'b11111110;
    endcase
end

endmodule