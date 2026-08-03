`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/31/2026 9:28:58 PM
// Design Name: 
// Module Name: argus_top
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


module argus_top #(
//  input logic clk,
//  input logic rst_n
//);

//byte_stream stream_if(clk, rst_n);
//mem mem_if(clk, rst_n);
//match_out match_if(clk, rst_n);

//ac_matcher matcher(
//.clk(clk),
//.rst_n(rst_n),
//.stream(stream_if),
//.mem_bus(mem_if),
//.mout(match_if)
//);

//slow_mem model(
//.clk(clk),
//.rst_n(rst_n),
//.mem_bus(mem_if)
//);
    parameter int state_w = 6,
    parameter int nLines = 8,
    parameter int mem_lat = 20,
    parameter string trans_mem = ""
) (
    input logic clk,
    input logic rst,
    byte_stream.src_mp bs,
    match_out.src_mp match,
    output logic [31:0] hits,
    output logic [31:0] misses
);

mem i_mc();
mem i_cs();

ac_matcher #(.STATE_W(state_w)) u_matcher (
    .clk(clk), .rst(rst),
    .bs(bs),
    .mem_if(i_mc.mem_mp),
    .match(match)
);

cache #(.state_w(state_w), .nLines(nLines)) u_cache (
    .clk(clk), .rst(rst),
    .from_matcher(i_mc.cache_mp),
    .to_sm(i_cs.mem_mp),
    .hits(hits),
    .misses(misses)
);

slow_mem #(
    .STATE_W(state_w),
    .MEM_LATENCY(mem_lat),
    .TRANS_MEM(trans_mem)
) u_slow_mem (
    .clk(clk), .rst(rst),
    .mem_if(i_cs.cache_mp)
);
endmodule
