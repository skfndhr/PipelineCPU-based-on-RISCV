`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/06 23:33:01
// Design Name: 
// Module Name: MyBUS
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


module MyBUS(
    input clk,
    input rst,
    input [4:0] BTN,              // 5个按钮输入
    input [15:0] SW,              // 16个开关输入
    input [31:0] PC,              // 程序计数器（用于显示）
    input mem_w,                  // 内存写使能
    input [31:0] Cpu_data2bus,    // CPU写入总线的数据
    input [31:0] addr_bus,        // 地址总线
    input [31:0] ram_data_out,    // RAM读出的数据
    input [15:0] led_out,         // LED当前输出值（用于读回）
    input [31:0] counter_out,     // 计数器当前值（用于读回）
    input counter0_out,           // 计数器0溢出输出
    input counter1_out,           // 计数器1溢出输出
    input counter2_out,           // 计数器2溢出输出
    
    output reg [31:0] Cpu_data4bus,   // 输出到CPU的数据
    output [31:0] ram_data_in,        // 写入RAM的数据
    output [9:0] ram_addr,            // RAM地址（字寻址，10位=4KB）
    output data_ram_we,               // RAM写使能
    output GPIOf0000000_we,           // GPIO F0000000 写使能（LED）
    output GPIOe0000000_we,           // GPIO E0000000 写使能（7-Segment）
    output counter_we,                // 计数器写使能
    output [31:0] Peripheral_in       // 写入外设的数据
);


    wire ram_sel;
    assign ram_sel = (addr_bus[31:24] != 8'hF0) && 
                     (addr_bus[31:24] != 8'hE0);
 
    wire gpio_f0_sel;
    assign gpio_f0_sel = (addr_bus[31:8] == 24'hF00000);  
    

    wire gpio_e0_sel;
    assign gpio_e0_sel = (addr_bus[31:5] == 27'h7000000);

    wire counter_sel;
    assign counter_sel = (addr_bus[31:4] == 28'h4000000); 
    

    assign ram_addr = addr_bus[11:2];        // 字地址（10位，4KB范围）
    assign ram_data_in = Cpu_data2bus;       // 直通CPU数据到RAM
    assign data_ram_we = mem_w & ram_sel;    // RAM写使能
    

    assign GPIOf0000000_we = mem_w & gpio_f0_sel;   // LED写使能
    assign GPIOe0000000_we = mem_w & gpio_e0_sel;   // 7-Segment写使能
    assign counter_we = mem_w & counter_sel;         // 计数器写使能
    

    assign Peripheral_in = Cpu_data2bus;
    

    always @(*) begin
        case (1'b1)
            ram_sel:        Cpu_data4bus = ram_data_out;           // RAM数据
            gpio_f0_sel:    Cpu_data4bus = {11'b0, BTN, SW};       // 读按钮+开关
            counter_sel:    Cpu_data4bus = counter_out;            // 读计数器
            default:        Cpu_data4bus = 32'h0000_0000;          // 默认0
        endcase
    end

endmodule
