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


module cache #(
    parameter int state_w = 6,
    parameter int nLines = 8
) (
    input logic clk,
    input logic rst,
    mem.cache_mp from_matcher,
    mem.mem_mp to_sm,
    output logic [31:0] hits,
    output logic [31:0] misses
);

localparam idxBits = $clog2(nLines);
localparam tagW = state_w - idxBits;
localparam rowW = 256 * state_w;

logic [rowW-1:0] cdata [nLines];
logic [tagW-1:0] ctag [nLines];
logic cvalid [nLines];

logic [idxBits-1:0] idx;
logic [tagW-1:0] req_tag;
assign idx = from_matcher.state_addr[idxBits-1:0];
assign req_tag = from_matcher.state_addr[state_w-1:idxBits];

logic hit;
assign hit = cvalid[idx] && (ctag[idx] == req_tag);

typedef enum logic {idle, fetch} fsm_t;
fsm_t st;

assign from_matcher.ack = (st == idle) ? (from_matcher.req && hit) : to_sm.ack; //hit: ack fires same cycle as req, zero latency
assign from_matcher.row_data = hit ? cdata[idx] : to_sm.row_data;

assign to_sm.req = (st == fetch);
assign to_sm.state_addr = from_matcher.state_addr;

always_ff @(posedge clk) begin
    if (rst) begin
        st <= idle;
        hits <= 0;
        misses <= 0;
        for (int i = 0; i < nLines; i++) cvalid[i] <= 0;
    end else case (st)
        idle: if (from_matcher.req) begin
            if (hit)
                hits <= hits + 1;
            else begin
                misses <= misses + 1;
                st <= fetch;
            end
        end

        fetch: if (to_sm.ack) begin
            cdata[idx] <= to_sm.row_data;
            ctag[idx]  <= req_tag;
            cvalid[idx] <= 1;
            st <= idle;
        end
    endcase
end

endmodule
