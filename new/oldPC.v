`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/20 15:10:45
// Design Name: 
// Module Name: PC
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


module oldPC(
    clk,
    rstn,
    NPC,
    PCWr,
    PC
    );
    input clk;
    input rstn;
    input [31:0] NPC;
    input PCWr;
    output reg [31:0]PC;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) PC <= 0;
        else if (PCWr) PC <= NPC;
        else PC <= PC;
    end
endmodule
