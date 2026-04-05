`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/20 14:52:08
// Design Name: 
// Module Name: MyCPU
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


module MyCPU(clk, reset, MIO_ready, inst_in, Data_in, mem_w, 
  PC_out, Addr_out, Data_out, dm_ctrl, CPU_MIO, INT);
    input clk;
    input reset;
    input MIO_ready;
    input [31:0]inst_in;
    input [31:0]Data_in;
    output mem_w;
    output [31:0]PC_out;
    output [31:0]Addr_out;
    output [31:0]Data_out;
    output [2:0]dm_ctrl;
    output CPU_MIO;
    input INT;





    wire rstn=~reset;
    wire Clk_CPU=clk;
    wire [31:0] instr=inst_in;
    wire [6:0]Op=instr[6:0];
    wire [6:0]Funct7=instr[31:25];
    wire [2:0]Funct3=instr[14:12];
    wire [4:0]rs1=instr[19:15];
    wire [4:0]rs2=instr[24:20];
    wire [4:0]rd=instr[11:7];
    wire [11:0]iimm=instr[31:20];
    wire [11:0]simm={instr[31:25],instr[11:7]};
    wire [5:0] EXTOp;
    wire [4:0] ALUOp;
    wire [2:0] NPCOp;
    wire ALUSrc;
    wire [2:0] DMType;
    wire [1:0] WDSel;
    wire RegWrite;
    wire MemWrite;
    wire [7:0] Zero;
    reg [31:0] WD;
    wire [31:0] RD1, RD2;
    wire [31:0] immout;
    wire[31:0] A;
    wire[31:0] B;
    wire [31:0] ALUresult;
    wire [31:0] PC;
    wire [31:0] NPC;
    wire PCWr=INT;




    assign B = (ALUSrc) ? immout : RD2;
    assign A = (ALUOp==5'b10000) ? PC : RD1;
    assign PC_out=PC;
    assign mem_w=MemWrite;
    assign Addr_out=ALUresult;
    assign Data_out=RD2;
    assign dm_ctrl=DMType;

    oldcontrol U_CONTROL(
        .Op(Op),
        .Funct7(Funct7),
        .Funct3(Funct3),
        .Zero(Zero[0]),
        .RegWrite(RegWrite),
        .MemWrite(MemWrite),
        .EXTOp(EXTOp),
        .ALUOp(ALUOp),
        .NPCOp(NPCOp),
        .ALUSrc(ALUSrc),
        .DMType(DMType),
        .WDSel(WDSel)
    );

    oldRF U_RF(
        .Clk_CPU(Clk_CPU),
        .rstn(rstn),
        .RFWr(RegWrite),
        .A1(rs1),
        .A2(rs2),
        .A3(rd),
        .WD(WD),
        .RD1(RD1),
        .RD2(RD2)
    );

    oldEXT U_EXT(
        .iimm_shamt(instr[24:20]),
        .iimm(iimm),
        .simm(simm),
        .bimm({instr[31],instr[7],instr[30:25],instr[11:8]}),
        .uimm(instr[31:12]),
        .jimm({instr[31],instr[19:12],instr[20],instr[30:21]}),
        .EXTOp(EXTOp),
        .immout(immout)
    );

    ALU U_ALU(
        .A(A),
        .B(B),
        .ALUop(ALUOp),
        .C(ALUresult),
        .Zero(Zero)
    );

    always @*
        begin
            case(WDSel)
                2'b00: WD<=ALUresult;
                2'b01: WD<=Data_in;
                2'b10: WD<=PC + 4;
            endcase
        end
    oldPC U_PC(
        .clk(Clk_CPU),
        .rstn(rstn),
        .NPC(NPC),
        .PCWr(PCWr),
        .PC(PC)   
    );
    oldNPC U_NPC(
        .PC(PC),
        .NPCOp(NPCOp),
        .imm(immout),
        .aluout(ALUresult),
        .NPC(NPC)
    );
    













endmodule
