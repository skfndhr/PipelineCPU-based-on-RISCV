`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/27 15:47:34
// Design Name: 
// Module Name: GRE_array
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


module GRE_array #(parameter WIDTH = 200)(
    input clk,
    input rst,
    input en,
    input flush,
    input [WIDTH-1:0] in,
    output reg [WIDTH-1:0] out
);
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            out <= 0;
        end else if (en) begin
            if (flush) begin
                out <= 0;
            end else begin
                out <= in;
            end
        end
        else begin
            out <= out; 
        end
    end
endmodule
