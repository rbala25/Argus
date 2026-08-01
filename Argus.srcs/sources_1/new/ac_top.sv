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


module argus_top(
  input logic clk,
  input logic rst_n
);

byte_stream stream_if(clk, rst_n);
mem mem_if(clk, rst_n);
match_out match_if(clk, rst_n);

ac_matcher matcher(
.clk(clk),
.rst_n(rst_n),
.stream(stream_if),
.mem_bus(mem_if),
.mout(match_if)
);

slow_mem model(
.clk(clk),
.rst_n(rst_n),
.mem_bus(mem_if)
);
endmodule
