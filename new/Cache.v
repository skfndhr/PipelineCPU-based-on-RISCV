`timescale 1ns / 1ps
`define IDLE 2'b00
`define READ 2'b01
`define WRITE 2'b10

module Cache(
    input clk,
    input rst,
    input  [9:0]  addra,
    input  [31:0] dina,
    input  [3:0]  wea,
    input  [127:0] data_from_mem,
    output [127:0] data_to_mem,
    output mem_stall,
    output [31:0] douta,
    output hit
    ); 

    wire [3:0] offset=addra[3:0];
    wire [24:0] tag_in=addra[31:7];
    wire [2:0] index=addra[6:4];
    wire choose0=(index==3'b000);
    wire choose1=(index==3'b001);
    wire choose2=(index==3'b010);
    wire choose3=(index==3'b011);
    wire choose4=(index==3'b100);
    wire choose5=(index==3'b101);
    wire choose6=(index==3'b110);
    wire choose7=(index==3'b111);
    wire hit_signals[0:7];
    wire miss=!(hit_signals[0] || hit_signals[1] || hit_signals[2] || hit_signals[3] || hit_signals[4] || hit_signals[5] || hit_signals[6] || hit_signals[7]);
    reg [1:0] status;
    reg [1:0] counter;
    wire mem_stall_signal=(status==`READ);
    assign mem_stall=mem_stall_signal;
    wire valid_from_mem=mem_stall_signal;
    always @(posedge clk or negedge rst)
    begin
        if(!rst)
        begin
            status<=`IDLE;
            counter<=2'b00;
        end
        else
        begin
            case(status)
                `IDLE:begin
                    if(miss)
                    begin
                        status<=`READ;
                        counter<=2'b01;
                    end
                    else
                    begin
                        status<=`IDLE;
                    end
                end
                `READ:begin
                    if(counter==2'b01)
                    begin
                        status<=`READ;
                        counter<=2'b10;
                    end
                    else
                    begin
                        status<=`IDLE;
                        counter<=2'b00;
                    end
                end
                `WRITE:begin
                    if(counter==2'b01)
                    begin
                        status<=`WRITE;
                        counter<=2'b10;
                    end
                    else
                    begin
                        status<=`READ;
                        counter<=2'b01;
                    end
                end
            endcase
        end
    end
    






    cache_set cache_set0(
        .clk(clk),
        .rst(rst),
        .offset(offset),
        .tag_in(tag_in),
        .choose(choose0), 
        .wea(wea),
        .din(dina),
        .data_from_mem(data_from_mem), 
        .valid_from_mem(mem_stall_signal), 
        .dout(douta),
        .hit(hit_signals[0]) 
    );
    cache_set cache_set1(
        .clk(clk),
        .rst(rst),
        .offset(offset),
        .tag_in(tag_in),
        .choose(choose1), 
        .wea(wea),
        .din(dina),
        .data_from_mem(data_from_mem), 
        .valid_from_mem(mem_stall_signal), 
        .dout(douta),
        .hit(hit_signals[1])
    );
    cache_set cache_set2(
        .clk(clk),
        .rst(rst),
        .offset(offset),
        .tag_in(tag_in),
        .choose(choose2), 
        .wea(wea),
        .din(dina),
        .data_from_mem(data_from_mem), 
        .valid_from_mem(mem_stall_signal), 
        .dout(douta),
        .hit(hit_signals[2]) 
    );
    cache_set cache_set3(
        .clk(clk),
        .rst(rst),
        .offset(offset),
        .tag_in(tag_in),
        .choose(choose3), 
        .wea(wea),
        .din(dina),
        .data_from_mem(data_from_mem), 
        .valid_from_mem(mem_stall_signal), 
        .dout(douta),
        .hit(hit_signals[3]) 
    );
    cache_set cache_set4(
        .clk(clk),
        .rst(rst),
        .offset(offset),
        .tag_in(tag_in),
        .choose(choose4), 
        .wea(wea),
        .din(dina),
        .data_from_mem(data_from_mem), 
        .valid_from_mem(mem_stall_signal), 
        .dout(douta),
        .hit(hit_signals[4]) 
    );
    cache_set cache_set5(
        .clk(clk),
        .rst(rst),
        .offset(offset),
        .tag_in(tag_in),
        .choose(choose5), 
        .wea(wea),
        .din(dina),
        .data_from_mem(data_from_mem), 
        .valid_from_mem(mem_stall_signal), 
        .dout(douta),
        .hit(hit_signals[5]) 
    );
    cache_set cache_set6(
        .clk(clk),
        .rst(rst),
        .offset(offset),
        .tag_in(tag_in),
        .choose(choose6), 
        .wea(wea),
        .din(dina),
        .data_from_mem(data_from_mem), 
        .valid_from_mem(mem_stall_signal),
        .dout(douta),
        .hit(hit_signals[6]) 
    );
    cache_set cache_set7(
        .clk(clk),
        .rst(rst),
        .offset(offset),
        .tag_in(tag_in),
        .choose(choose7), 
        .wea(wea),
        .din(dina),
        .data_from_mem(data_from_mem), 
        .valid_from_mem(mem_stall_signal), 
        .dout(douta),
        .hit(hit_signals[7]) 
    );

endmodule
