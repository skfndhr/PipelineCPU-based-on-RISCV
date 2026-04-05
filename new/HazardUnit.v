module HazardUnit(
    input  [4:0] IF_ID_rs1,
    input  [4:0] IF_ID_rs2,
    input  [4:0] EX_rs1,
    input  [4:0] EX_rs2,
    input  [4:0] EX_rd,
    input  [4:0] MEM_rd,
    input  [4:0] WB_rd,
    input        EX_RegWrite,
    input        MEM_RegWrite,
    input        WB_RegWrite,
    input  [1:0] EX_WDSel,
    input  [2:0] EX_NPCOp,
    input        EX_Zero,
    output reg   PCWrite,
    output reg   IF_ID_Write,
    output reg   ID_EX_Flush,
    output reg   IF_ID_Flush,
    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB
);

    wire EX_MemRead = (EX_WDSel == 2'b01);
    wire branch_taken = EX_NPCOp[1] | EX_NPCOp[2] | (EX_NPCOp[0] & EX_Zero);
    wire load_use_stall = EX_MemRead && (
        (EX_rd != 5'b00000) &&
        ((EX_rd == IF_ID_rs1) || (EX_rd == IF_ID_rs2))
    );

    always @(*) begin

        if (load_use_stall) begin
            PCWrite     = 1'b0;
            IF_ID_Write = 1'b0;
            ID_EX_Flush = 1'b1;
            IF_ID_Flush = 1'b0;
        end else begin
            PCWrite     = 1'b1;
            IF_ID_Write = 1'b1;
            ID_EX_Flush = branch_taken;
            IF_ID_Flush = branch_taken;
        end


        if (MEM_RegWrite && (MEM_rd != 5'b00000) && (MEM_rd == EX_rs1)) begin
            ForwardA = 2'b10; // forward from EX/MEM
        end else if (WB_RegWrite && (WB_rd != 5'b00000) && (WB_rd == EX_rs1)) begin
            ForwardA = 2'b01; // forward from MEM/WB
        end else begin
            ForwardA = 2'b00;
        end

        if (MEM_RegWrite && (MEM_rd != 5'b00000) && (MEM_rd == EX_rs2)) begin
            ForwardB = 2'b10;
        end else if (WB_RegWrite && (WB_rd != 5'b00000) && (WB_rd == EX_rs2)) begin
            ForwardB = 2'b01;
        end else begin
            ForwardB = 2'b00;
        end
    end
endmodule