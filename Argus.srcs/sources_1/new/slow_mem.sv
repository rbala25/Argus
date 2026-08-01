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



endmodule
