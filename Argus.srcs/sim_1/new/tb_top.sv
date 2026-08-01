`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Rishi Bala
// 
// Create Date: 07/31/2026 11:38:20 PM
// Design Name: 
// Module Name: tb_top
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


module tb_top;

logic clk;
logic rst_n;

initial clk = 0;
always #5 clk = ~clk; //10ns

byte_stream stream_if(clk, rst_n); //interfaces
mem mem_if(clk, rst_n);
match_out match_if(clk, rst_n);

ac_matcher matcher(
.clk(clk),
.rst_n(rst_n),
.stream(stream_if),
.mem_bus(mem_if),
.mout(match_if)
);

slow_mem #(.latency(5)) model(
.clk(clk),
.rst_n(rst_n),
.mem_bus(mem_if)
);
  
  
endmodule
