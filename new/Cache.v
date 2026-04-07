`timescale 1ns / 1ps

module Cache #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter NUM_SETS   = 16,
    parameter NUM_WAYS   = 4,
    parameter LINE_WORDS = 4
)(
    input                       clk,
    input                       rstn,
    input                       cpu_req,
    input                       cpu_wr,
    input      [3:0]            cpu_wstrb,
    input      [ADDR_WIDTH-1:0] cpu_addr,
    input      [DATA_WIDTH-1:0] cpu_wdata,
    input      [DATA_WIDTH-1:0] mem_rdata,
    input                       mem_ready,
    output     [DATA_WIDTH-1:0] cpu_rdata,
    output                      stall_req,
    output                      pc_write,
    output                      if_id_write,
    output                      id_ex_write,
    output                      ex_mem_write,
    output                      mem_wb_write,
    output reg                  mem_req,
    output reg                  mem_wr,
    output reg [ADDR_WIDTH-1:0] mem_addr,
    output reg [DATA_WIDTH-1:0] mem_wdata,
    output reg [3:0]            mem_wstrb 
);
    function integer clog2;
        input integer value;
        integer temp;
        begin
            temp = value - 1;
            clog2 = 0;
            while (temp > 0) begin
                clog2 = clog2 + 1;
                temp = temp >> 1;
            end
        end
    endfunction

    localparam SET_BITS         = clog2(NUM_SETS);
    localparam WAY_BITS         = clog2(NUM_WAYS);
    localparam WORD_OFFSET_BITS = clog2(LINE_WORDS);
    localparam TAG_BITS         = ADDR_WIDTH - SET_BITS - WORD_OFFSET_BITS - 2;
    localparam LINE_BITS        = DATA_WIDTH * LINE_WORDS;
    localparam TOTAL_LINES      = NUM_SETS * NUM_WAYS;

    localparam [1:0] STATE_IDLE      = 2'd0;
    localparam [1:0] STATE_WRITEBACK = 2'd1;
    localparam [1:0] STATE_REFILL    = 2'd2;

    function [DATA_WIDTH-1:0] line_word;
        input [LINE_BITS-1:0] line;
        input [WORD_OFFSET_BITS-1:0] word_idx;
        begin
            line_word = line[word_idx * DATA_WIDTH +: DATA_WIDTH];
        end
    endfunction

    function [DATA_WIDTH-1:0] merge_word;
        input [DATA_WIDTH-1:0] old_word;
        input [DATA_WIDTH-1:0] new_word;
        input [3:0]            strb;
        integer byte_idx;
        begin
            merge_word = old_word;
            for (byte_idx = 0; byte_idx < DATA_WIDTH / 8; byte_idx = byte_idx + 1) begin
                if (strb[byte_idx]) begin
                    merge_word[byte_idx * 8 +: 8] = new_word[byte_idx * 8 +: 8];
                end
            end
        end
    endfunction

    function [LINE_BITS-1:0] write_line_word;
        input [LINE_BITS-1:0]        line;
        input [WORD_OFFSET_BITS-1:0] word_idx;
        input [DATA_WIDTH-1:0]       word_value;
        begin
            write_line_word = line;
            write_line_word[word_idx * DATA_WIDTH +: DATA_WIDTH] = word_value;
        end
    endfunction

    reg [TAG_BITS-1:0]  tag_array   [0:TOTAL_LINES-1];
    reg [LINE_BITS-1:0] data_array  [0:TOTAL_LINES-1];
    reg [1:0]           lru_array   [0:TOTAL_LINES-1];
    reg                 valid_array [0:TOTAL_LINES-1];
    reg                 dirty_array [0:TOTAL_LINES-1];

    reg [1:0]                  state;
    reg [SET_BITS-1:0]         miss_set;
    reg [TAG_BITS-1:0]         miss_tag;
    reg [WORD_OFFSET_BITS-1:0] miss_word;
    reg [WAY_BITS-1:0]         victim_way;
    reg [TAG_BITS-1:0]         victim_tag;
    reg [LINE_BITS-1:0]        victim_line;
    reg [1:0]                  victim_age;
    reg                        victim_was_valid;
    reg [WORD_OFFSET_BITS-1:0] burst_count;
    reg [LINE_BITS-1:0]        refill_line;
    reg                        pending_wr;
    reg [3:0]                  pending_wstrb;
    reg [DATA_WIDTH-1:0]       pending_wdata;

    wire [WORD_OFFSET_BITS-1:0] addr_word = cpu_addr[2 + WORD_OFFSET_BITS - 1:2];
    wire [SET_BITS-1:0]         addr_set  = cpu_addr[2 + WORD_OFFSET_BITS + SET_BITS - 1:2 + WORD_OFFSET_BITS];
    wire [TAG_BITS-1:0]         addr_tag  = cpu_addr[ADDR_WIDTH-1:2 + WORD_OFFSET_BITS + SET_BITS];

    reg                    hit;
    reg [WAY_BITS-1:0]     hit_way;
    reg [LINE_BITS-1:0]    hit_line;
    reg [DATA_WIDTH-1:0]   hit_word_data;
    reg [1:0]              hit_age;
    reg [WAY_BITS-1:0]     replace_way;
    reg                    found_invalid;
    reg [1:0]              replace_age;

    integer comb_way;
    integer comb_index;
    integer reset_index;
    integer access_index;
    integer refill_index;
    reg [LINE_BITS-1:0]  next_line_data;
    reg [DATA_WIDTH-1:0] next_word_data;

    task touch_lru;
        input [SET_BITS-1:0] set_idx;
        input [WAY_BITS-1:0] used_way;
        input                used_valid;
        input [1:0]          used_age;
        integer lru_way;
        integer lru_index;
        begin
            for (lru_way = 0; lru_way < NUM_WAYS; lru_way = lru_way + 1) begin
                lru_index = set_idx * NUM_WAYS + lru_way;
                if (lru_way == used_way) begin
                    lru_array[lru_index] <= 2'd0;
                end else if (valid_array[lru_index]) begin
                    if (used_valid) begin
                        if (lru_array[lru_index] < used_age) begin
                            lru_array[lru_index] <= lru_array[lru_index] + 2'd1;
                        end
                    end else if (lru_array[lru_index] != 2'd3) begin
                        lru_array[lru_index] <= lru_array[lru_index] + 2'd1;
                    end
                end
            end
        end
    endtask

    always @(*) begin
        hit           = 1'b0;
        hit_way       = {WAY_BITS{1'b0}};
        hit_line      = {LINE_BITS{1'b0}};
        hit_word_data = {DATA_WIDTH{1'b0}};
        hit_age       = 2'd0;
        replace_way   = {WAY_BITS{1'b0}};
        found_invalid = 1'b0;
        replace_age   = 2'd0;

        for (comb_way = 0; comb_way < NUM_WAYS; comb_way = comb_way + 1) begin
            comb_index = addr_set * NUM_WAYS + comb_way;
            if (valid_array[comb_index] && (tag_array[comb_index] == addr_tag) && !hit) begin
                hit           = 1'b1;
                hit_way       = comb_way[WAY_BITS-1:0];
                hit_line      = data_array[comb_index];
                hit_word_data = line_word(data_array[comb_index], addr_word);
                hit_age       = lru_array[comb_index];
            end
        end

        for (comb_way = 0; comb_way < NUM_WAYS; comb_way = comb_way + 1) begin
            comb_index = addr_set * NUM_WAYS + comb_way;
            if (!found_invalid && !valid_array[comb_index]) begin
                found_invalid = 1'b1;
                replace_way   = comb_way[WAY_BITS-1:0];
                replace_age   = lru_array[comb_index];
            end else if (!found_invalid && (lru_array[comb_index] >= replace_age)) begin
                replace_way = comb_way[WAY_BITS-1:0];
                replace_age = lru_array[comb_index];
            end
        end
    end

    assign cpu_rdata   = ((state == STATE_IDLE) && hit) ? hit_word_data : {DATA_WIDTH{1'b0}};
    assign stall_req   = (state != STATE_IDLE) || (cpu_req && !hit);
    assign pc_write    = ~stall_req;
    assign if_id_write = ~stall_req;
    assign id_ex_write = ~stall_req;
    assign ex_mem_write = ~stall_req;
    assign mem_wb_write = ~stall_req;

    always @(*) begin
        mem_req   = 1'b0;
        mem_wr    = 1'b0;
        mem_addr  = {ADDR_WIDTH{1'b0}};
        mem_wdata = {DATA_WIDTH{1'b0}};
        mem_wstrb = 4'b0000;

        case (state)
            STATE_WRITEBACK: begin
                mem_req   = 1'b1;
                mem_wr    = 1'b1;
                mem_addr  = {victim_tag, miss_set, burst_count, 2'b00};
                mem_wdata = line_word(victim_line, burst_count);
                mem_wstrb = 4'b1111;
            end
            STATE_REFILL: begin
                mem_req   = 1'b1;
                mem_wr    = 1'b0;
                mem_addr  = {miss_tag, miss_set, burst_count, 2'b00};
                mem_wdata = {DATA_WIDTH{1'b0}};
                mem_wstrb = 4'b0000;
            end
            default: begin
                mem_req   = 1'b0;
                mem_wr    = 1'b0;
                mem_addr  = {ADDR_WIDTH{1'b0}};
                mem_wdata = {DATA_WIDTH{1'b0}};
                mem_wstrb = 4'b0000;
            end
        endcase
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state            <= STATE_IDLE;
            miss_set         <= {SET_BITS{1'b0}};
            miss_tag         <= {TAG_BITS{1'b0}};
            miss_word        <= {WORD_OFFSET_BITS{1'b0}};
            victim_way       <= {WAY_BITS{1'b0}};
            victim_tag       <= {TAG_BITS{1'b0}};
            victim_line      <= {LINE_BITS{1'b0}};
            victim_age       <= 2'd0;
            victim_was_valid <= 1'b0;
            burst_count      <= {WORD_OFFSET_BITS{1'b0}};
            refill_line      <= {LINE_BITS{1'b0}};
            pending_wr       <= 1'b0;
            pending_wstrb    <= 4'b0000;
            pending_wdata    <= {DATA_WIDTH{1'b0}};

            for (reset_index = 0; reset_index < TOTAL_LINES; reset_index = reset_index + 1) begin
                tag_array[reset_index]   <= {TAG_BITS{1'b0}};
                data_array[reset_index]  <= {LINE_BITS{1'b0}};
                lru_array[reset_index]   <= 2'd0;
                valid_array[reset_index] <= 1'b0;
                dirty_array[reset_index] <= 1'b0;
            end
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (cpu_req) begin
                        if (hit) begin
                            access_index = addr_set * NUM_WAYS + hit_way;
                            if (cpu_wr) begin
                                next_word_data = merge_word(hit_word_data, cpu_wdata, cpu_wstrb);
                                next_line_data = write_line_word(hit_line, addr_word, next_word_data);
                                data_array[access_index] <= next_line_data;
                                dirty_array[access_index] <= 1'b1;
                            end
                            touch_lru(addr_set, hit_way, 1'b1, hit_age);
                        end else begin
                            access_index      = addr_set * NUM_WAYS + replace_way;
                            miss_set          <= addr_set;
                            miss_tag          <= addr_tag;
                            miss_word         <= addr_word;
                            victim_way        <= replace_way;
                            victim_tag        <= tag_array[access_index];
                            victim_line       <= data_array[access_index];
                            victim_age        <= lru_array[access_index];
                            victim_was_valid  <= valid_array[access_index];
                            pending_wr        <= cpu_wr;
                            pending_wstrb     <= cpu_wstrb;
                            pending_wdata     <= cpu_wdata;
                            burst_count       <= {WORD_OFFSET_BITS{1'b0}};
                            refill_line       <= {LINE_BITS{1'b0}};
                            if (valid_array[access_index] && dirty_array[access_index]) begin
                                state <= STATE_WRITEBACK;
                            end else begin
                                state <= STATE_REFILL;
                            end
                        end
                    end
                end

                STATE_WRITEBACK: begin
                    if (mem_ready) begin
                        if (burst_count == LINE_WORDS - 1) begin
                            burst_count <= {WORD_OFFSET_BITS{1'b0}};
                            state       <= STATE_REFILL;
                        end else begin
                            burst_count <= burst_count + 1'b1;
                        end
                    end
                end

                STATE_REFILL: begin
                    if (mem_ready) begin
                        next_line_data = write_line_word(refill_line, burst_count, mem_rdata);
                        if (burst_count == LINE_WORDS - 1) begin
                            refill_index = miss_set * NUM_WAYS + victim_way;
                            if (pending_wr) begin
                                next_word_data = merge_word(line_word(next_line_data, miss_word), pending_wdata, pending_wstrb);
                                next_line_data = write_line_word(next_line_data, miss_word, next_word_data);
                            end
                            data_array[refill_index]  <= next_line_data;
                            tag_array[refill_index]   <= miss_tag;
                            valid_array[refill_index] <= 1'b1;
                            dirty_array[refill_index] <= pending_wr;
                            refill_line               <= {LINE_BITS{1'b0}};
                            burst_count               <= {WORD_OFFSET_BITS{1'b0}};
                            touch_lru(miss_set, victim_way, victim_was_valid, victim_age);
                            state                     <= STATE_IDLE;
                        end else begin
                            refill_line <= next_line_data;
                            burst_count <= burst_count + 1'b1;
                        end
                    end
                end

                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end
endmodule
