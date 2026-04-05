`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/07 19:19:37
// Design Name: 
// Module Name: RF
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


module RF( 
    input	Clk_CPU,							//100MHZ CLK
    input	rstn,							//reset signal
    input	RFWr,						//Rfwrite = mem2reg  
    input 	[4:0] A1, A2, A3,		// Register Num 
    input 	[31:0] WD,					//Write data
    output reg [31:0] RD1, RD2          //Data output port
);
    integer i;
    
    reg [31:0] RF[0:31];            

    always @(posedge Clk_CPU or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < 32; i=i+1) begin
                RF[i] <= 0;
            end
            RF[2] <= 32'h000003FF; // Stack Pointer initialization
        end
        else if (RFWr) begin
            if (A3 != 0) RF[A3] <= WD;
        end
    end

    always @(*) begin
        if (!rstn) begin
            RD1 = 0;
            RD2 = 0;
        end else begin
            RD1 = (A1 != 0) ? RF[A1] : 0;
            RD2 = (A2 != 0) ? RF[A2] : 0;
            if (RFWr && (A3 != 0)) begin
                if (A1 == A3) RD1 = WD;
                if (A2 == A3) RD2 = WD;
            end
        end
    end
endmodule

