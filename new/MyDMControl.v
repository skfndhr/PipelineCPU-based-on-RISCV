`timescale 1ns / 1ps
`define dm_word 3'b000
`define dm_halfword 3'b001
`define dm_halfword_unsigned 3'b010
`define dm_byte 3'b011
`define dm_byte_unsigned 3'b100
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/20 16:10:06
// Design Name: 
// Module Name: MyDMControl
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


module MyDMControl(
    mem_w, 
    Addr_in, 
    Data_write, 
    dm_ctrl, 
    Data_read_from_dm, 
    Data_read, Data_write_to_dm, 
    wea_mem
    );
    input mem_w;
    input [31:0]Addr_in;
    input [31:0]Data_write;
    input [2:0]dm_ctrl;
    input [31:0]Data_read_from_dm;

    output reg [31:0]Data_read;
    output reg [31:0]Data_write_to_dm;
    output reg [3:0]wea_mem;



    wire [1:0] addr_low = Addr_in[1:0];
    wire [15:0] halfword = (addr_low[1] ? Data_read_from_dm[31:16] : Data_read_from_dm[15:0]);
    wire [7:0] byte_data =
        (addr_low == 2'b00) ? Data_read_from_dm[7:0] :
        (addr_low == 2'b01) ? Data_read_from_dm[15:8] :
        (addr_low == 2'b10) ? Data_read_from_dm[23:16] :
                              Data_read_from_dm[31:24];

    always @* begin
        Data_read = 32'b0;
        Data_write_to_dm = 32'b0;
        wea_mem = 4'b0000;

        case (dm_ctrl)
            3'b000: begin // sw
                wea_mem = mem_w ? 4'b1111 : 4'b0000;
                Data_write_to_dm = Data_write;
            end
            3'b001: begin // lh/sh
                case (addr_low)
                    2'b00: begin wea_mem = mem_w ? 4'b0011 : 4'b0000; Data_write_to_dm = {16'b0, Data_write[15:0]}; end
                    2'b10: begin wea_mem = mem_w ? 4'b1100 : 4'b0000; Data_write_to_dm = {Data_write[15:0], 16'b0}; end
                    default: begin
                        wea_mem = mem_w ? 4'b0110 : 4'b0000;
                        Data_write_to_dm = {8'b0, Data_write[15:0], 8'b0};
                    end
                endcase
            end
            3'b011: begin // lb/sb
                case (addr_low)
                    2'b00: begin wea_mem = mem_w ? 4'b0001 : 4'b0000; Data_write_to_dm = {24'b0, Data_write[7:0]}; end
                    2'b01: begin wea_mem = mem_w ? 4'b0010 : 4'b0000; Data_write_to_dm = {16'b0, Data_write[7:0], 8'b0}; end
                    2'b10: begin wea_mem = mem_w ? 4'b0100 : 4'b0000; Data_write_to_dm = {8'b0, Data_write[7:0], 16'b0}; end
                    2'b11: begin wea_mem = mem_w ? 4'b1000 : 4'b0000; Data_write_to_dm = {Data_write[7:0], 24'b0}; end
                endcase
            end
            default: begin 
                wea_mem = 4'b0000;
                Data_write_to_dm = 32'b0;
            end
        endcase

        case (dm_ctrl)
            3'b000: Data_read = Data_read_from_dm; 
            3'b001: Data_read = {{16{halfword[15]}}, halfword};
            3'b010: Data_read = {16'b0, halfword}; 
            3'b011: Data_read = {{24{byte_data[7]}}, byte_data}; 
            3'b100: Data_read = {24'b0, byte_data}; 
            default: Data_read = Data_read_from_dm;
        endcase
    end

endmodule