`timescale 1ns / 1ps


// bit[5]: way3 > way2 
// bit[4]: way3 > way1
// bit[3]: way3 > way0
// bit[2]: way2 > way1
// bit[1]: way2 > way0
// bit[0]: way1 > way0
// initially 6'b111111, means all lines are empty and the next line to replace is way0
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/08 12:26:00
// Design Name: 
// Module Name: cache_set
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cache_set(
    input clk,
    input rst,
    input [3:0]offset,
    input [24:0] tag_in,
    input choose,
    input [3:0]wea,
    input [31:0] din,
    input [127:0] data_from_mem,
    input valid_from_mem,
    output [31:0] dout,
    output hit
    );
    reg [5:0] lru;
    reg [31:0] data_out;
    wire valid_from_mem1;
    wire valid_from_mem2; 
    wire valid_from_mem3;
    wire valid_from_mem4;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            lru <= 6'b111111; // All lines are empty, next to replace is way0
            data_out <= 32'b0;
        end     
    end

    assign valid_from_mem1 = choose && valid_from_mem && lru[0] && lru[1] && lru[3]; // way0 is LRU
    assign valid_from_mem2 = choose && valid_from_mem && (!lru[0]) && lru[2] && lru[4]; // way1 is LRU
    assign valid_from_mem3 = choose && valid_from_mem && (!lru[1]) && (!lru[2]) && lru[5]; // way2 is LRU
    assign valid_from_mem4 = choose && valid_from_mem && (!lru[3]) && (!lru[4]) && (!lru[5]); // way3 is LRU
    
    wire [31:0] dout1;
    wire [31:0] dout2;
    wire [31:0] dout3;
    wire [31:0] dout4;
    wire hit1;
    wire hit2;
    wire hit3;
    wire hit4;
    cache_line cacheline1(
        .clk(clk),
        .rst(rst),
        .offset(offset),
        .tag_in(tag_in),
        .choose(choose),
        .wea(wea),
        .din(din),
        .data_from_mem(data_from_mem),
        .valid_from_mem(valid_from_mem1),
        .dout(dout1),
        .hit(hit1)
    );
    cache_line cacheline2(
        .clk(clk),
        .rst(rst),
        .offset(offset),
        .tag_in(tag_in),
        .choose(choose),
        .wea(wea),
        .din(din),
        .data_from_mem(data_from_mem),
        .valid_from_mem(valid_from_mem2),
        .dout(dout2),
        .hit(hit2)
    );
    cache_line cacheline3(
        .clk(clk),
        .rst(rst),
        .offset(offset),
        .tag_in(tag_in),
        .choose(choose),
        .wea(wea),
        .din(din),
        .data_from_mem(data_from_mem),
        .valid_from_mem(valid_from_mem3),
        .dout(dout3),
        .hit(hit3)
    );
    cache_line cacheline4(
        .clk(clk),
        .rst(rst),
        .offset(offset),
        .tag_in(tag_in),
        .choose(choose),
        .wea(wea),
        .din(din),
        .data_from_mem(data_from_mem),
        .valid_from_mem(valid_from_mem4),
        .dout(dout4),
        .hit(hit4)
    );
    always @* begin
        data_out <= hit1 ? dout1 : (hit2 ? dout2 : (hit3 ? dout3 : (hit4 ? dout4 : 32'b0)));
    end
    assign dout = data_out;
    assign hit = hit1 || hit2 || hit3 || hit4;
endmodule
