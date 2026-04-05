`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/20 14:47:17
// Design Name: 
// Module Name: control
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


module oldcontrol(
    input [6:0] Op,  //opcode
    input [6:0] Funct7,  //funct7 
    input [2:0] Funct3,    // funct3 
    input Zero,
    output RegWrite, // control signal for register write
    output MemWrite, // control signal for memory write
    output	[5:0]EXTOp,    // control signal to signed extension
    output [4:0] ALUOp,    // ALU opertion
    output [2:0] NPCOp,    // next pc operation
    output ALUSrc,   // ALU source for b
    output [2:0] DMType, //dm r/w type
    output [1:0] WDSel    // (register) write data selection  (MemtoReg)
);
    wire rtype  = ~Op[6]&Op[5]&Op[4]&~Op[3]&~Op[2]&Op[1]&Op[0]; //0110011
    wire i_add=rtype&~Funct7[6]&~Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]&~Funct3[2]&~Funct3[1]&~Funct3[0]; // add 0000000 000
    wire i_sub=rtype&~Funct7[6]&Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]&~Funct3[2]&~Funct3[1]&~Funct3[0]; // sub 0100000 000
    wire i_slt=rtype&~Funct7[6]&~Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]&~Funct3[2]&Funct3[1]&~Funct3[0]; // slt 0000000 010
    wire i_sll=rtype&~Funct7[6]&~Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]&~Funct3[2]&~Funct3[1]&Funct3[0]; // sll 0000000 001
    wire i_sltu=rtype&~Funct7[6]&~Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]&~Funct3[2]&Funct3[1]&Funct3[0]; // sltu 0000000 011
    wire i_xor=rtype&~Funct7[6]&~Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]&Funct3[2]&~Funct3[1]&~Funct3[0]; // xor 0000000 100
    wire i_srl=rtype&~Funct7[6]&~Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]&Funct3[2]&~Funct3[1]&Funct3[0]; // srl 0000000 101
    wire i_sra=rtype&~Funct7[6]&Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]&Funct3[2]&~Funct3[1]&Funct3[0]; // sra 0100000 101
    wire i_or=rtype&~Funct7[6]&~Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]&Funct3[2]&Funct3[1]&~Funct3[0]; // or 0000000 110
    wire i_and=rtype&~Funct7[6]&~Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]&Funct3[2]&Funct3[1]&Funct3[0]; // and 0000000 111

    wire itype_l  = ~Op[6]&~Op[5]&~Op[4]&~Op[3]&~Op[2]&Op[1]&Op[0]; //0000011
    wire i_lb=itype_l&~Funct3[2]& ~Funct3[1]& ~Funct3[0]; //lb 000
    wire i_lh=itype_l&~Funct3[2]& ~Funct3[1]& Funct3[0];  //lh 001
    wire i_lw=itype_l&~Funct3[2]& Funct3[1]& ~Funct3[0];  //lw 010
    wire i_lbu=itype_l&Funct3[2]& ~Funct3[1]& ~Funct3[0]; //lbu 100
    wire i_lhu=itype_l&Funct3[2]& ~Funct3[1]& Funct3[0]; //lhu 101

    wire itype_r  = ~Op[6]&~Op[5]&Op[4]&~Op[3]&~Op[2]&Op[1]&Op[0]; //0010011
    wire i_addi  =  itype_r& ~Funct3[2]& ~Funct3[1]& ~Funct3[0]; // addi 000 func3
    wire i_slti  =  itype_r& ~Funct3[2]& Funct3[1]& ~Funct3[0]; // slti 010
    wire i_sltiu =  itype_r& ~Funct3[2]& Funct3[1]& Funct3[0]; // sltiu 011
    wire i_xori  =  itype_r& Funct3[2]& ~Funct3[1]& ~Funct3[0]; // xori 100
    wire i_ori   =  itype_r& Funct3[2]& Funct3[1]& ~Funct3[0]; // ori 110
    wire i_andi  =  itype_r& Funct3[2]& Funct3[1]& Funct3[0]; // andi 111
    wire i_slli  =  itype_r& ~Funct3[2]& ~Funct3[1]& Funct3[0]; // slli 001
    wire i_srli  =  itype_r& Funct3[2]& ~Funct3[1]& Funct3[0]&~Funct7[5]; // srli 101
    wire i_srai  =  itype_r& Funct3[2]& ~Funct3[1]& Funct3[0]&Funct7[5]; // srai 101

    wire stype=~Op[6]&Op[5]&~Op[4]&~Op[3]&~Op[2]&Op[1]&Op[0];//0100011
    wire i_sw=stype&~Funct3[2]&Funct3[1]&~Funct3[0]; // sw 010
    wire i_sb=stype&~Funct3[2]&~Funct3[1]&~Funct3[0]; // sb 000
    wire i_sh=stype&~Funct3[2]&~Funct3[1]&Funct3[0]; // sh 001

    wire btype=Op[6]&Op[5]&~Op[4]&~Op[3]&~Op[2]&Op[1]&Op[0];//1100011
    wire i_beq=btype&~Funct3[2]&~Funct3[1]&~Funct3[0]; // beq 000
    wire i_bne=btype&~Funct3[2]&~Funct3[1]&Funct3[0]; // bne 001
    wire i_blt=btype&Funct3[2]&~Funct3[1]&~Funct3[0]; // blt 100
    wire i_bge=btype&Funct3[2]&~Funct3[1]&Funct3[0]; // bge 101
    wire i_bltu=btype&Funct3[2]&Funct3[1]&~Funct3[0]; // bltu 110
    wire i_bgeu=btype&Funct3[2]&Funct3[1]&Funct3[0]; // bgeu 111

    wire i_jal=Op[6]&Op[5]&~Op[4]&Op[3]&Op[2]&Op[1]&Op[0]; //1101111
    wire i_jalr=Op[6]&Op[5]&~Op[4]&~Op[3]&Op[2]&Op[1]&Op[0]; //1100111
    wire i_lui=~Op[6]&Op[5]&Op[4]&~Op[3]&Op[2]&Op[1]&Op[0]; //0110111
    wire i_auipc=~Op[6]&~Op[5]&Op[4]&~Op[3]&Op[2]&Op[1]&Op[0]; //0010111

    assign RegWrite = i_add | i_sub | i_slt | i_sll | i_sltu | i_xor | i_srl | i_sra | i_or | i_and |
                      i_lb | i_lh | i_lw | i_lbu | i_lhu |i_addi | i_slti | i_sltiu | i_xori | i_ori |
                      i_andi | i_slli | i_srli | i_srai |i_jal | i_jalr | i_lui | i_auipc;
    //assign RegWrite = 1;
    assign MemWrite = i_sw | i_sb | i_sh;

    // assign EXTOp=(itype_r|itype_l|i_jalr?,stype,btype,i_lui|i_auipc,i_jal);
    assign EXTOp=((itype_r|itype_l|i_jalr)&~i_slli&~i_srli&~i_srai)?6'b100000:
                 stype?6'b010000:
                 btype?6'b001000:
                 i_lui|i_auipc?6'b000100:
                 i_jal?6'b000010:
                 i_slli|i_srli|i_srai?6'b000001:
                 6'b111111;
    // assign EXTOp=itype_r?6'b100000:
    //              stype?6'b010000:
    //              btype?6'b001000:
    //              i_lui|i_auipc?6'b000100:
    //              i_jal?6'b000010:
    //              i_slli|i_srli|i_srai?6'b000001:
    //              6'b111111;
    assign ALUSrc = itype_r|itype_l|i_jal|i_jalr|i_lui|i_auipc|stype;
    assign ALUOp=
        i_add|i_addi|itype_l|stype|i_jalr?5'b00000:
        i_sub|i_beq?5'b00001:
        i_slt|i_slti?5'b00010:
        i_sltu|i_sltiu?5'b00011:
        i_xor|i_xori?5'b00100:
        i_srl|i_srli?5'b00101:
        i_sra|i_srai?5'b00110:
        i_or|i_ori?5'b00111:
        i_and|i_andi?5'b01000:
        i_sll|i_slli?5'b01001:
        i_bne?5'b01010:
        i_blt?5'b01011:
        i_bge?5'b01100:
        i_bltu?5'b01101:
        i_bgeu?5'b01110:
        i_lui|i_jal?5'b01111:
        i_auipc?5'b10000:
        5'b11111;
    assign DMType[2]=i_lbu;
    assign DMType[1]=i_lb | i_sb | i_lhu;
    assign DMType[0]=i_lh | i_sh | i_lb | i_sb;
    //mem2reg=wdsel ,WDSel_FromALU 2'b00  WDSel_FromMEM 2'b01  WDSel_FromPCplus4 2'b10
    assign WDSel[0] = itype_l;
    assign WDSel[1] = i_jal|i_jalr|i_auipc;
    



    assign NPCOp[0]=btype&Zero;
    assign NPCOp[1]=i_jal;
    assign NPCOp[2]=i_jalr;
        


endmodule
