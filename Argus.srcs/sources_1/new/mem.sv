`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Rishi Bala
// 
// Create Date: 07/04/2026 11:58:58 PM
// Design Name: 
// Module Name: mem
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

interface mem_if #(
    parameter STATE_W = 6
)(
    input logic clk,
    input logic rst_n
);
    logic req;
    logic [STATE_W-1:0] state_addr;
    logic ack;
    logic [STATE_W*256-1:0] row_data;

    modport cache_mp(
        output req,
        output state_addr,
        input ack,
        input row_data
    );

    modport mem_mp(
        input req,
        input state_addr,
        output ack,
        output row_data
    );

    clocking cache_cb @(posedge clk);
        output req, state_addr;
        input ack, row_data;
    endclocking

    clocking mem_cb @(posedge clk);
        input req, state_addr;
        output ack, row_data;
    endclocking
endinterface