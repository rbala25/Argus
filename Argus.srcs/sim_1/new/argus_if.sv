`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Rishi Bala
// 
// Create Date: 08/03/2026 06:15:32 PM
// Design Name: 
// Module Name: argus_if
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


interface argus_if #( //argus top io
  parameter MATCH_W = 4,
  parameter STATE_W = 6
)(input logic clk);

  logic rst;
  logic bs_valid;
  logic [7:0] bs_data;
  
  logic bs_ready;
  logic match_valid;
  logic [MATCH_W-1:0] match_id;
  logic [STATE_W-1:0] match_state;
  
  logic [31:0] hits;
  logic [31:0] misses;
  logic ready;
endinterface
