`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/13 14:21:04
// Design Name: 
// Module Name: TOP
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


module TOP(
    input rstn,
    input [4:0]btn_i,
    input [15:0]sw_i,
    input clk,

    output[7:0] disp_an_o,
    output[7:0] disp_seg_o,

    output[15:0] led_o
    );
    wire rst;
    assign rst = ~rstn;
    wire [4:0] BTN_out;
    wire [15:0] SW_out;
    wire Clk_CPU;
    wire[31:0] clkdiv;
    wire Clk_CPU_N;
    assign Clk_CPU_N = ~Clk_CPU;
    wire [15:0] LED_out;
    wire [1:0] counter_set;
    wire [15:0] led;
    wire counter0_OUT;
    wire counter1_OUT;
    wire counter2_OUT;
    wire [31:0] spo;
    wire [31:0] Data_read;
    wire [31:0] Data_write_to_dm;
    wire [3:0] wea_mem;
    wire clkn;
    assign clkn=~clk;
    wire [31:0] douta;
    wire [31:0] Addr_out;
    wire CPU_MIO;
    wire [31:0] Data_out;
    wire [31:0] PC_out;
    wire [2:0] dm_ctrl;
    wire mem_w;
    wire [31:0] Cpu_data4bus;
    wire GPIOe0000000_we;
    wire GPIOf0000000_we;
    wire [31:0]Peripheral_in;
    wire counter_we;
    wire [9:0] ram_addr;
    wire [31:0] ram_data_in;
    wire [31:0] Disp_num;
    wire [7:0] LE_out;
    wire [7:0] point_out;
    wire [31:0] counter_out;
    wire [7:0] seg_an;
    wire [7:0] seg_sout;
    wire [31:0] data3;
    wire mem_stall;

    MyPipelineCPU U1_SCPU(
        .Data_in(Data_read),
        .INT(counter0_OUT),
        .MIO_ready(CPU_MIO),
        .clk(Clk_CPU),
        .inst_in(spo),
        .reset(rst),
        .Addr_out(Addr_out),
        .CPU_MIO(CPU_MIO),
        .Data_out(Data_out),
        .PC_out(PC_out),
        .dm_ctrl(dm_ctrl),
        .mem_w(mem_w),
        .mem_stall(mem_stall)
    );


    ROM_D U2_ROMD(
        .a(PC_out[11:2]),
        .spo(spo)
    );



    MyDMControl U3_dm_controller(
        .Addr_in(Addr_out),
        .Data_read_from_dm(Cpu_data4bus),
        .Data_write(ram_data_in),
        .dm_ctrl(dm_ctrl),
        .mem_w(mem_w),
        .Data_read(Data_read),
        .Data_write_to_dm(Data_write_to_dm),
        .wea_mem(wea_mem)
    );



    // Cache U3_Cache(
    //     .clk(Clk_CPU),
    //     .rst(rst),
    //     .addra(ram_addr),
    //     .dina(Data_write_to_dm),
    //     .wea(wea_mem),
    //     .data_from_mem(douta),
    //     .mem_stall(mem_stall),
    //     .douta(douta),
    //     .hit()
    // );



    RAM_B U3_RAMB(
        .addra(ram_addr),
        .clka(clkn),
        .dina(Data_write_to_dm),
        .wea(wea_mem),
        .douta(douta)
    );

    MyBUS U4_MIO_BUS(
        .BTN(BTN_out),
        .Cpu_data2bus(Data_out),
        .SW(SW_out),
        .addr_bus(Addr_out),
        .clk(clk),
        .counter_out(data3),
        .counter0_out(counter0_OUT),
        .counter1_out(counter1_OUT),
        .counter2_out(counter2_OUT),
        .led_out(LED_out),
        .mem_w(mem_w),
        .ram_data_out(douta),
        .rst(rst),
        .Cpu_data4bus(Cpu_data4bus),
        .GPIOe0000000_we(GPIOe0000000_we),
        .GPIOf0000000_we(GPIOf0000000_we),
        .Peripheral_in(Peripheral_in),
        .counter_we(counter_we),
        .ram_addr(ram_addr),
        .ram_data_in(ram_data_in)
    );



    Multi_8CH32 U5_Multi_8CH32(
        .EN(GPIOe0000000_we),
        .LES(~64'h00000000),
        .Switch(SW_out[7:5]),
        .clk(Clk_CPU_N),
        .data0(Peripheral_in),
        .data1({1'b0,1'b0,PC_out[31:2]}),
        .data2(spo),
        .data3(counter_out),
        .data4(Addr_out),
        .data5(Data_out),
        .data6(Cpu_data4bus),
        .data7(PC_out),
        .point_in({clkdiv[31:0],clkdiv[31:0]}),
        .rst(rst),
        .Disp_num(Disp_num),
        .LE_out(LE_out),
        .point_out(point_out)
    );



    SSeg7 U6_SSeg7(
        .Hexs(Disp_num),
        .LES(LE_out),
        .SW0(SW_out[0]),
        .clk(clk),
        .flash(clkdiv[10]),
        .point(point_out),
        .rst(rst),
        .seg_an(seg_an),
        .seg_sout(seg_sout)
    );



    SPIO U7_SPIO(
        .EN(GPIOf0000000_we),
        .P_Data(Peripheral_in),
        .clk(Clk_CPU_N),
        .rst(rst),
        .LED_out(LED_out),
        .counter_set(counter_set),
        .led(led)
    );



    clk_div U8_clk_div(
        .SW2(SW_out[2]),
        .clk(clk),
        .rst(rst),
        .clkdiv(clkdiv),
        .Clk_CPU(Clk_CPU)
    );




    Counter_x U9_Counter_x(
        .clk(Clk_CPU_N),
        .clk0(clkdiv[6]),
        .clk1(clkdiv[9]),
        .clk2(clkdiv[11]),
        .counter_ch(counter_set),
        .counter_val(Peripheral_in),
        .counter_we(counter_we),
        .rst(rst),
        .counter0_OUT(counter0_OUT),
        .counter1_OUT(counter1_OUT),
        .counter2_OUT(counter2_OUT)
    );




    Enter U10_Enter(        
        .BTN(btn_i),
        .SW(sw_i),
        .clk(clk),
        .BTN_out(BTN_out),
        .SW_out(SW_out)
    );


    assign disp_an_o = seg_an;
    assign disp_seg_o = seg_sout;
    assign led_o = led;

















endmodule
