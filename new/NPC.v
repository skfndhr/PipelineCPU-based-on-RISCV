`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/20 15:10:45
// Design Name: 
// Module Name: NPC
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


module NPC(
    NPCOp,
    PCPlus4,
    PCPlusimm,
    aluout,
    NPC
    );
    input [2:0] NPCOp;
    input [31:0] PCPlus4;
    input [31:0] PCPlusimm;
    input [31:0]aluout;
    output reg [31:0] NPC;
    
    always @(*) begin
        case (NPCOp)
            3'b000: NPC <= PCPlus4;
            3'b001: NPC <= PCPlusimm;
            3'b010: NPC <= PCPlusimm;
            3'b100: NPC <= aluout;
            default:NPC <= PCPlus4;
        endcase
    end
endmodule
