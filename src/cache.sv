`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Rishi Bala
// 
// Create Date: 08/02/2026 10:12:34 PM
// Design Name: 
// Module Name: cache
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


//module cache #(
//    parameter int state_w = 6,
//    parameter int nLines = 8
//) (
//    input logic clk,
//    input logic rst,
//    mem.cache_mp from_matcher,
//    mem.mem_mp to_sm,
//    output logic [31:0] hits,
//    output logic [31:0] misses
//);

//localparam idxBits = $clog2(nLines);
//localparam tagW = state_w - idxBits;
//localparam rowW = 256 * state_w;

//logic [rowW-1:0] cdata [nLines];
//logic [tagW-1:0] ctag [nLines];
//logic cvalid [nLines];

//logic [idxBits-1:0] idx;
//logic [tagW-1:0] req_tag;
//assign idx = from_matcher.state_addr[idxBits-1:0];
//assign req_tag = from_matcher.state_addr[state_w-1:idxBits];

//logic hit;
//assign hit = cvalid[idx] && (ctag[idx] == req_tag);

//typedef enum logic {idle, fetch} fsm_t;
//fsm_t st;

//assign from_matcher.ack = (st == idle) ? (from_matcher.req && hit) : to_sm.ack; //hit: ack fires same cycle as req, zero latency
//assign from_matcher.row_data = hit ? cdata[idx] : to_sm.row_data;

//assign to_sm.req = (st == fetch);
//assign to_sm.state_addr = from_matcher.state_addr;

//always_ff @(posedge clk) begin
//    if (rst) begin
//        st <= idle;
//        hits <= 0;
//        misses <= 0;
//        for (int i = 0; i < nLines; i++) cvalid[i] <= 0;
//    end else case (st)
//        idle: if (from_matcher.req) begin
//            if (hit)
//                hits <= hits + 1;
//            else begin
//                misses <= misses + 1;
//                st <= fetch;
//            end
//        end

//        fetch: if (to_sm.ack) begin
//            cdata[idx] <= to_sm.row_data;
//            ctag[idx]  <= req_tag;
//            cvalid[idx] <= 1;
//            st <= idle;
//        end
//    endcase
//end

//endmodule

module cache #(
    parameter int state_w = 6,
    parameter int nLines = 8,
    parameter int POLICY = 0,
    parameter [nLines*state_w-1:0] HOT_STATES = 0
)(
    input logic clk,
    input logic rst,
    mem.cache_mp from_matcher,
    mem.mem_mp to_sm,
    output logic [31:0] hits,
    output logic [31:0] misses,
    output logic ready
);

localparam WAYS_W = $clog2(nLines);
localparam rowW = 256 * state_w;

logic [rowW-1:0] cdata [nLines];
logic [state_w-1:0] ctag [nLines];
logic cvalid [nLines];

logic hit;
logic [WAYS_W-1:0] hit_way;
always_comb begin
    hit = 0; hit_way = 0;
    for (int i = 0; i < nLines; i++)
        if (cvalid[i] && ctag[i] == from_matcher.state_addr) begin
            hit = 1;
            hit_way = WAYS_W'(i);
        end
end

logic [WAYS_W-1:0] age [nLines];
logic [WAYS_W-1:0] fifo_ptr;
logic [15:0] lfsr;
logic [WAYS_W-1:0] victim, vlat;
logic [WAYS_W-1:0] preload_idx;
logic [state_w-1:0] pend_addr;

always_comb begin
    victim = 0;
    case (POLICY)
        1: victim = fifo_ptr;
        2: begin
            for (int i = 1; i < nLines; i++)
                if (age[i] > age[victim]) victim = WAYS_W'(i);
        end
        3: victim = lfsr[WAYS_W-1:0];
        default: victim = fifo_ptr;
    endcase
end

typedef enum logic [2:0] {boot, pload, pgap, idle, fetch, fill} cst_t;
cst_t cs;

always_ff @(posedge clk)
    if (rst) lfsr <= 16'hACE1;
    else lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};

assign ready = (cs != boot && cs != pload && cs != pgap);

assign from_matcher.ack = (cs == idle && from_matcher.req && hit) || (cs == fill);
assign from_matcher.row_data = (cs == fill) ? cdata[vlat] : cdata[hit_way];
assign to_sm.req = (cs == pload || cs == fetch);
assign to_sm.state_addr = (cs == pload) ? HOT_STATES[preload_idx*state_w +: state_w] : pend_addr;

always_ff @(posedge clk) begin
    if (rst) begin
        cs <= boot;
        preload_idx <= 0; fifo_ptr <= 0;
        hits <= 0; misses <= 0;
        for (int i = 0; i < nLines; i++) begin
            cvalid[i] <= 0;
            age[i] <= WAYS_W'(i);
        end
    end else case (cs)

        boot: cs <= (POLICY == 0) ? pload : idle;

        pload: if (to_sm.ack) begin
            cdata[preload_idx] <= to_sm.row_data;
            ctag[preload_idx] <= HOT_STATES[preload_idx*state_w +: state_w];
            cvalid[preload_idx] <= 1;
            cs <= pgap;
        end

        pgap: begin
            if (preload_idx == WAYS_W'(nLines-1)) cs <= idle;
            else begin
                preload_idx <= preload_idx + 1;
                cs <= pload;
            end
        end

        idle: if (from_matcher.req) begin
            if (hit) begin
                hits <= hits + 1;
                if (POLICY == 2)
                    for (int i = 0; i < nLines; i++)
                        age[i] <= (i == int'(hit_way)) ? 0 :
                                   (age[i] < WAYS_W'(nLines-1)) ? age[i]+1 : age[i];
            end else begin
                misses <= misses + 1;
                pend_addr <= from_matcher.state_addr;
                vlat <= victim;
                cs <= fetch;
            end
        end

        fetch: if (to_sm.ack) begin
            cdata[vlat] <= to_sm.row_data;
            ctag[vlat] <= pend_addr;
            cvalid[vlat] <= 1;
            cs <= fill;
        end

        fill: begin
            if (POLICY == 1) fifo_ptr <= fifo_ptr + 1;
            if (POLICY == 2)
                for (int i = 0; i < nLines; i++)
                    age[i] <= (i == int'(vlat)) ? 0 :
                               (age[i] < WAYS_W'(nLines-1)) ? age[i]+1 : age[i];
            cs <= idle;
        end

    endcase
end

endmodule