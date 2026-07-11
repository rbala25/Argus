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
  parameter int state_w = 6,
  parameter int match_id = 8,
  parameter int numStates = 47,
  parameter logic [state_w-1:0] ROOT_STATE = 0,
  parameter string MATCH_FILE = "match.mem")
  (input logic clk,
  input logic rst_n,
  byte_stream.dut_mp stream,
  mem.cache_mp mem_bus,
  match_out.dut_mp mout
);

  typedef enum logic {idle, lookup} state_e;
  state_e fsm;
 
  logic [state_w-1:0] current_state;
  logic [7:0] in_byte;
  logic [state_w-1:0] next_state;
 
  logic [match_id-1:0] match_rom [numStates]; //from match.mem
  initial $readmemh(MATCH_FILE, match_rom);

  assign next_state = mem_bus.row_data[in_byte*state_w +: state_w]; //256 transitions for one state
 
  assign stream.ready = (fsm == idle); //only when idle
  assign mem_bus.req = (fsm == lookup);
  assign mem_bus.state_addr = current_state;
 
  assign mout.current_state = current_state;
  
    always_ff @(posedge clk) begin
    if (!rst_n) begin
      fsm <= idle;
      current_state <= ROOT_STATE;
      in_byte <= 0;
      mout.match_valid <= 0;
      mout.match_id <= 0;
    end else begin
      mout.match_valid <= 0;
      case (fsm)
        idle: begin
          if (stream.valid && stream.ready) begin
            in_byte <= stream.data;
            fsm <= lookup;
          end
        end
        lookup: begin
          if (mem_bus.ack) begin
            current_state <= next_state;
            mout.match_id <= match_rom[next_state];
            mout.match_valid <= (match_rom[next_state] != 0);
            fsm <= idle;
          end
        end
      endcase
    end
  end


endmodule
