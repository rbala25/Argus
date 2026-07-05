`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Rishi Bala
// 
// Create Date: 07/04/2026 11:58:58 PM
// Design Name: 
// Module Name: byte_stream
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

interface byte_stream_if(
    input logic clk,
    input logic rst_n
);
    logic valid;
    logic [7:0] data;
    logic ready;

    modport dut_mp(
        input valid,
        input data,
        output ready
    );

    clocking driver_cb @(posedge clk);
        output valid, data;
        input ready;
    endclocking

    clocking monitor_cb @(posedge clk);
        input valid, data, ready;
    endclocking
endinterface
