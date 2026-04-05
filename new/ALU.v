`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/20 14:30:16
// Design Name: 
// Module Name: ALU
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



//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/21 17:47:54
// Design Name: 
// Module Name: ALU
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


module ALU( 
    input signed [31:0] 	A, B,
    input [4:0] ALUop,
    output signed [31:0] C,
    output reg [7:0] Zero
); 
    reg signed [31:0] result;
    
    always @(*) begin
        case (ALUop)
            5'b00000:  result = A + B;               // add
            5'b00001:  result = A - B;
            5'b00010:  result = ($signed(A) < $signed(B)) ? 1 : 0;      // slt
            5'b00011:  result = ($unsigned(A) < $unsigned(B)) ? 1 : 0;      // sltu  
            5'b00100:  result = A ^ B;            
            5'b00101:  result = A >> B;    //srl
            5'b00110:  result = $signed(A) >>> B;
            5'b00111:  result = A | B;
            5'b01000:  result = A & B;
            5'b01001:  result = A << B;
            5'b01010:  result = {31'b0,(A==B)};
            5'b01011:  result = {31'b0,(A>=B)};
            5'b01100:  result = {31'b0,(A<B)};
            5'b01101:  result = {31'b0,($unsigned(A)>=$unsigned(B))};
            5'b01110:  result = {31'b0,($unsigned(A)<$unsigned(B))};
            5'b01111:  result = B;
            default:   result = 0;
        endcase
        if (result == 0)
            Zero = 8'b00000001;
        else
            Zero = 8'b00000000;
    end

    assign C = result;

endmodule


