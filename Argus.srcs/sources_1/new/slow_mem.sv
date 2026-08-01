`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Rishi Bala
// 
// Create Date: 07/31/2026 6:14:42 PM
// Design Name: 
// Module Name: slow_mem
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


module slow_mem #( //stand in for ddr3
  parameter int state_w = 6,
  parameter int num_states = 47,
  parameter int latency = 20,
  parameter string mem_file = "transition.mem"
)(
  input logic clk,
  input logic rst_n,
  mem.mem_mp mem_bus
);

localparam int row_w = state_w * 256;

logic [state_w-1:0] trans_flat [0:num_states*256-1];
initial $readmemh(mem_file, trans_flat);

function automatic logic [row_w-1:0] build_row(input logic [state_w-1:0] s); //single row
logic [row_w-1:0] r;
for (int b = 0; b < 256; b++) begin
  r[b*state_w +: state_w] = trans_flat[int'(s)*256 + b];
end
return r;
endfunction

typedef enum logic [1:0] {s_idle, s_wait, s_done} state_t;
state_t fsm;

logic [$clog2(latency+1)-1:0] cnt;
logic [state_w-1:0] addr_q;
logic [row_w-1:0] row_q;

endmodule
