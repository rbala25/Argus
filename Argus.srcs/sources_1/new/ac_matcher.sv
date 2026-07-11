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

  typedef enum logic {S_IDLE, S_LOOKUP} state_e;
  state_e fsm;
 
  logic [STATE_W-1:0] current_state;
  logic [7:0] in_byte;
  logic [STATE_W-1:0] next_state;
 
  logic [MATCH_ID_W-1:0] match_rom [NUM_STATES]; //from match.mem
  initial $readmemh(MATCH_FILE, match_rom);

  assign next_state = mem_bus.row_data[in_byte*STATE_W +: STATE_W]; //256 transitions for one state
 
  assign stream.ready = (fsm == S_IDLE); //only when idle
  assign mem_bus.req = (fsm == S_LOOKUP);
  assign mem_bus.state_addr = current_state;
 
  assign mout.current_state = current_state;


endmodule
