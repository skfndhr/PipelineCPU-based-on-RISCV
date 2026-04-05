`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/01 20:21:08
// Design Name: 
// Module Name: MyPipelineCPU
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


module MyPipelineCPU(clk, reset, MIO_ready, inst_in, Data_in, mem_w, 
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

    wire [5:0] EXTOp;
    wire [4:0] ALUOp;
    wire [2:0] NPCOp;
    wire ALUSrc;
    wire [2:0] DMType;
    wire [1:0] WDSel;
    wire RegWrite;
    wire WB_RegWrite;
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
    wire PCWr = PCWrite;
    wire [31:0] EX_instr;
    wire [31:0] EX_PC;
    wire [31:0] EX_PCPlus4;
    wire [31:0] EX_RD1;
    wire [31:0] EX_RD2;
    wire [31:0] EX_immout;
    wire EX_RegWrite;
    wire EX_MemWrite;
    wire EX_ALUSrc;
    wire [4:0] EX_ALUOp;
    wire [2:0] EX_NPCOp;
    wire [2:0] EX_DMType;
    wire [1:0] EX_WDSel;
    wire [31:0] PCPlus4;
    wire [2:0] MEM_NPCOp;
    wire [31:0] EX_PCPlusimm;
    wire [31:0] MEM_PCPlusimm;
    wire [31:0] MEM_ALUresult;
    wire [31:0] MEM_RD2;
    wire [31:0] ID_instr;
    wire [31:0] ID_PC;
    wire [31:0] ID_PCPlus4;
    wire [2:0] MEM_DMtype;
    wire MEM_MemWrite;
    wire [31:0] WB_Data_in;
    wire [31:0] WB_ALUresult;
    wire [31:0] WB_PCPlus4;
    wire [1:0]WB_WDSel;
    wire [199:0]IF_ID_in;
    wire [199:0]IF_ID_out;
    wire [299:0]ID_EX_in;
    wire [299:0]ID_EX_out;
    wire [299:0]EX_MEM_in;
    wire [299:0]EX_MEM_out;
    wire [349:0]MEM_WB_in;
    wire [349:0]MEM_WB_out;
    wire [1:0] ForwardA;
    wire [1:0] ForwardB;
    wire [4:0] IF_ID_rs1 = ID_instr[19:15];
    wire [4:0] IF_ID_rs2 = ID_instr[24:20];
    wire [4:0] EX_rs1 = EX_instr[19:15];
    wire [4:0] EX_rs2 = EX_instr[24:20];
    wire [4:0] EX_rd  = EX_instr[11:7];
    wire [4:0] MEM_rd = EX_MEM_out[11:7];
    wire [4:0] WB_rd  = MEM_WB_out[11:7];
    wire [2:0]NPCop;

    assign PC_out=PC;
    assign mem_w=MEM_MemWrite;
    assign Addr_out=MEM_ALUresult;
    assign Data_out=MEM_RD2;
    assign dm_ctrl=MEM_DMtype;
    
    NPC U_NPC(
        .NPCOp(NPCop),
        .PCPlus4(PCPlus4),
        .PCPlusimm(EX_PCPlusimm),
        .aluout(ALUresult),
        .NPC(NPC)
    );
    PC U_PC(
        .clk(Clk_CPU),
        .rstn(rstn),
        .NPC(NPC),
        .PCWr(PCWr),
        .PC(PC)   
    );
    Adder U_Adder(
        .PC(PC),
        .PCPlus4(PCPlus4)
    );
    assign IF_ID_in[31:0]   = instr;
    assign IF_ID_in[63:32]  = PC;
    assign IF_ID_in[95:64]  = PCPlus4;
    assign IF_ID_in[199:96] = 104'd0;

    GRE_array #(.WIDTH(200)) IF_ID(
        .clk(Clk_CPU),
        .rst(rstn),
        .en(IF_ID_Write),
        .flush(IF_ID_Flush),
        .in(IF_ID_in),
        .out(IF_ID_out)
    );



    assign ID_instr=IF_ID_out[31:0];
    assign ID_PC=IF_ID_out[63:32];
    assign ID_PCPlus4=IF_ID_out[95:64];

    wire [6:0]Op=ID_instr[6:0];
    wire [6:0]Funct7=ID_instr[31:25];
    wire [2:0]Funct3=ID_instr[14:12];
    wire [4:0]rs1=ID_instr[19:15];
    wire [4:0]rs2=ID_instr[24:20];
    wire [4:0]rd=ID_instr[11:7];


    RF U_RF(
        .Clk_CPU(Clk_CPU),
        .rstn(rstn),
        .RFWr(WB_RegWrite),
        .A1(rs1),
        .A2(rs2),
        .A3(WB_rd),
        .WD(WD),
        .RD1(RD1),
        .RD2(RD2)
    );
    EXT U_EXT(
        .iimm_shamt(ID_instr[24:20]),
        .iimm(ID_instr[31:20]),
        .simm({ID_instr[31:25],ID_instr[11:7]}),
        .bimm({ID_instr[31],ID_instr[7],ID_instr[30:25],ID_instr[11:8]}),
        .uimm(ID_instr[31:12]),
        .jimm({ID_instr[31],ID_instr[19:12],ID_instr[20],ID_instr[30:21]}),
        .EXTOp(EXTOp),
        .immout(immout)
    );
    control U_CONTROL(
        .Op(Op),
        .Funct7(Funct7),
        .Funct3(Funct3),
        .RegWrite(RegWrite),
        .MemWrite(MemWrite),
        .EXTOp(EXTOp),
        .ALUOp(ALUOp),
        .NPCOp(NPCOp),
        .ALUSrc(ALUSrc),
        .DMType(DMType),
        .WDSel(WDSel)
    );

    

    HazardUnit U_HAZARD(
        .IF_ID_rs1(IF_ID_rs1),
        .IF_ID_rs2(IF_ID_rs2),
        .EX_rs1(EX_rs1),
        .EX_rs2(EX_rs2),
        .EX_rd(EX_rd),
        .MEM_rd(MEM_rd),
        .WB_rd(WB_rd),
        .EX_RegWrite(EX_RegWrite),
        .MEM_RegWrite(MEM_RegWrite),
        .WB_RegWrite(WB_RegWrite),
        .EX_WDSel(EX_WDSel),
        .EX_NPCOp(EX_NPCOp),
        .EX_Zero(Zero[0]),
        .PCWrite(PCWrite),
        .IF_ID_Write(IF_ID_Write),
        .ID_EX_Flush(ID_EX_Flush),
        .IF_ID_Flush(IF_ID_Flush),
        .ForwardA(ForwardA),
        .ForwardB(ForwardB)
    );

    assign ID_EX_in[31:0]=ID_instr;
    assign ID_EX_in[63:32]=ID_PC;
    assign ID_EX_in[95:64]=ID_PCPlus4;
    assign ID_EX_in[98:96]=NPCOp;
    assign ID_EX_in[131:100]=RD1;
    assign ID_EX_in[163:132]=RD2;
    assign ID_EX_in[195:164]=immout;
    assign ID_EX_in[196]=RegWrite;
    assign ID_EX_in[197]=MemWrite;
    assign ID_EX_in[198]=ALUSrc;
    assign ID_EX_in[204:200]=ALUOp;
    assign ID_EX_in[207:205]=DMType;
    assign ID_EX_in[209:208]=WDSel;
    assign ID_EX_in[99]=1'b0;
    assign ID_EX_in[199]=1'b0;
    assign ID_EX_in[299:210]=90'd0;

    GRE_array #(.WIDTH(300)) ID_EX(
        .clk(Clk_CPU),
        .rst(rstn),
        .en(1'b1),
        .flush(ID_EX_Flush),
        .in(ID_EX_in),
        .out(ID_EX_out)
    );
    assign EX_instr=ID_EX_out[31:0];
    assign EX_PC=ID_EX_out[63:32];
    assign EX_PCPlus4=ID_EX_out[95:64];
    assign EX_RD1=ID_EX_out[131:100];
    assign EX_RD2=ID_EX_out[163:132];
    assign EX_immout=ID_EX_out[195:164];
    assign EX_RegWrite=ID_EX_out[196];
    assign EX_MemWrite=ID_EX_out[197];
    assign EX_ALUSrc=ID_EX_out[198];
    assign EX_ALUOp=ID_EX_out[204:200];
    assign EX_NPCOp=ID_EX_out[98:96];
    assign EX_DMType=ID_EX_out[207:205];
    assign EX_WDSel=ID_EX_out[209:208];

    wire [31:0] ForwardedA = (ForwardA == 2'b10) ? MEM_ALUresult :
                             (ForwardA == 2'b01) ? WD : EX_RD1;
    wire [31:0] ForwardedB = (ForwardB == 2'b10) ? MEM_ALUresult :
                             (ForwardB == 2'b01) ? WD : EX_RD2;

    assign B = (EX_ALUSrc) ? EX_immout : ForwardedB;
    assign A = (EX_ALUOp==5'b10000) ? EX_PC : ForwardedA;
    assign EX_PCPlusimm=EX_PC+EX_immout;

    
    ALU U_ALU(
        .A(A),
        .B(B),
        .ALUop(EX_ALUOp),
        .C(ALUresult),
        .Zero(Zero)
    );
    
    assign NPCop[0]=EX_NPCOp[0]&Zero[0];
    assign NPCop[1]=EX_NPCOp[1];
    assign NPCop[2]=EX_NPCOp[2];

    assign EX_MEM_in[95:0]=ID_EX_out[95:0];
    assign EX_MEM_in[99]=ID_EX_out[99];
    assign EX_MEM_in[209:164]=ID_EX_out[209:164];
    assign EX_MEM_in[131:100]=ForwardedA;
    assign EX_MEM_in[163:132]=ForwardedB;
    assign EX_MEM_in[98:96]=NPCop;
    assign EX_MEM_in[241:210]=ALUresult;
    assign EX_MEM_in[249:242]=Zero;
    assign EX_MEM_in[281:250]=EX_PCPlusimm;
    assign EX_MEM_in[299:282]=18'd0;

    GRE_array #(.WIDTH(300)) EX_MEM(
        .clk(Clk_CPU),
        .rst(rstn),
        .en(1'b1),
        .flush(1'b0),
        .in(EX_MEM_in),
        .out(EX_MEM_out)
    );

    wire [31:0] MEM_Data_in;
    assign MEM_NPCOp=EX_MEM_out[98:96];
    assign MEM_PCPlusimm=EX_MEM_out[281:250];
    assign MEM_ALUresult=EX_MEM_out[241:210];
    assign MEM_RD2=EX_MEM_out[163:132];
    assign MEM_DMtype=EX_MEM_out[207:205];
    assign MEM_MemWrite=EX_MEM_out[197];
    assign MEM_RegWrite=EX_MEM_out[196];
    
    assign MEM_Data_in=Data_in;


    assign MEM_WB_in[281:0]=EX_MEM_out[281:0];
    assign MEM_WB_in[299:282]=18'd0;
    assign MEM_WB_in[331:300]=MEM_Data_in;
    assign MEM_WB_in[349:332]=18'd0;

    GRE_array #(.WIDTH(350)) MEM_WB(
        .clk(Clk_CPU),
        .rst(rstn),
        .en(1'b1),
        .flush(1'b0),
        .in(MEM_WB_in),
        .out(MEM_WB_out)
    );
    
    assign WB_Data_in=MEM_WB_out[331:300];
    assign WB_ALUresult=MEM_WB_out[241:210];
    assign WB_PCPlus4=MEM_WB_out[95:64];
    assign WB_RegWrite=MEM_WB_out[196];
    assign WB_WDSel=MEM_WB_out[209:208];

    always @*
        begin
            case(WB_WDSel)
                2'b00: WD<=WB_ALUresult;
                2'b01: WD<=WB_Data_in;
                2'b10: WD<=WB_PCPlus4;
            endcase
        end


endmodule
