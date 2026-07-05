`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Rishi Bala
// 
// Create Date: 07/04/2026 11:58:58 PM
// Design Name: 
// Module Name: match_out
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

interface match_out_if #(
    parameter STATE_W = 6
)(
    input logic clk,
    input logic rst_n
);
    logic match_valid;
    logic [7:0] match_id;
    logic [STATE_W-1:0] current_state;

    modport dut_mp(
        output match_valid,
        output match_id,
        output current_state
    );

    clocking monitor_cb @(posedge clk);
        input match_valid, match_id, current_state;
    endclocking
endinterface