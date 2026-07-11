`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Rishi Bala
// 
// Create Date: 07/10/2026 10:08:50 PM
// Design Name: 
// Module Name: ac_matcher
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


module ac_matcher #(
  parameter int STATE_W = 6,
  parameter int MATCH_ID_W = 8,
  parameter int NUM_STATES = 47,
  parameter logic [STATE_W-1:0] ROOT_STATE = 0,
  parameter string MATCH_FILE = "match.mem")
  (input logic clk,
  input logic rst_n,
  byte_stream.dut_mp stream,
  mem.cache_mp mem_bus,
  match_out.dut_mp mout
);


endmodule
