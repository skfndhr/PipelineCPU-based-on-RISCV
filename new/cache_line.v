`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/08 12:26:00
// Design Name: 
// Module Name: cache_line
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


module cache_line(
    input clk,
    input rst,
    input [3:0]offset,
    input [24:0] tag_in,
    input choose,
    input [3:0]wea,
    input [31:0] din,
    input [127:0] data_from_mem,
    input valid_from_mem,
    output [127:0] data_to_mem,
    output [31:0] dout,
    output [24:0] tag_out,
    output hit,
    output dirty_out,
    output valid_out
    );
    reg isvalid;
    reg isdirty;
    reg [24:0] tag;
    reg [31:0] data[0:4];
    reg [31:0] data_out;
    integer i;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            isvalid <= 0;
            isdirty <= 0;
            tag <= 0;
            for (i = 0; i < 3; i=i+1) begin
                data[i] <= 0;
            end
        end else begin
            
            if (choose && valid_from_mem) begin
                isvalid <= 1;
                isdirty <= 0;
                tag <= tag_in;
                data[0] <= data_from_mem[31:0];
                data[1] <= data_from_mem[63:32];
                data[2] <= data_from_mem[95:64];
                data[3] <= data_from_mem[127:96];
            end
            if  (choose && valid && tag==tag_in) begin
                if (wea[0]) data[offset][7:0] <= din[7:0];
                if (wea[1]) data[offset][15:8] <= din[15:8];
                if (wea[2]) data[offset][23:16] <= din[23:16];
                if (wea[3]) data[offset][31:24] <= din[31:24];
                if(wea != 4'b0000) isdirty <= 1;
                data_out <= data[offset];
            end
            else begin                
                data_out <= 32'b0;
            end            
        end
    end
    assign dout = data_out;
    assign hit = choose && valid && tag==tag_in;
    assign data_to_mem = {data[3], data[2], data[1], data[0]};
    assign dirty = isdirty;
    assign valid = isvalid;
endmodule
