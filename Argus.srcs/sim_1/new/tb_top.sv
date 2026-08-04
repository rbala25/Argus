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

`include "uvm_macros.svh"
import uvm_pkg::*;
import argus_tb_pkg::*;

module tb_top;

//logic clk;
//logic rst_n;

//initial clk = 0;
//always #5 clk = ~clk; //10ns

//byte_stream stream_if(clk, rst_n);
//mem mem_if(clk, rst_n); //interfaces
//match_out match_if(clk, rst_n);

//ac_matcher #(.MATCH_FILE("C:/Vivado/Argus/scripts/match.mem")) matcher(
//  .clk(clk),
//  .rst_n(rst_n),
//  .stream(stream_if),
//  .mem_bus(mem_if),
//  .mout(match_if)
//);

//slow_mem #(.latency(5), .mem_file("C:/Vivado/Argus/scripts/transition.mem")) model(
//  .clk(clk),
//  .rst_n(rst_n),
//  .mem_bus(mem_if)
//);

//logic [31:0] hits, misses;
//argus_top #(
//    .match_mem("C:/Vivado/Argus/scripts/match.mem"),
//    .trans_mem("C:/Vivado/Argus/scripts/transition.mem"),
//    .mem_lat(5)
//) u_top (
//    .clk(clk),
//    .rst(~rst_n),
//    .bs(stream_if),
//    .match(match_if),
//    .hits(hits),
//    .misses(misses)
//);

//string test_str = "attack detected, running cmd.exe, found malware";

//task automatic drive_bytes(input string s);
//    for (int i = 0; i < s.len(); i++) begin
//      @(posedge clk);
//      stream_if.data = s[i];
//      stream_if.valid = 1;
//      while (!stream_if.ready) @(posedge clk);
//    end
//    @(posedge clk);
//    stream_if.valid = 0;
//    stream_if.data = 0;
//endtask

//int nbytes; //monitor, byte count
//always @(posedge clk) begin
//if (rst_n) begin
//  if (match_if.match_valid)
//    $display("[%0t] MATCH id=%0d state=%0d after byte index %0d",
//             $time, match_if.match_id, match_if.current_state, nbytes-1);
//  if (stream_if.valid && stream_if.ready)
//    nbytes++;
//end
//end

////run
//initial begin
//stream_if.valid = 0;
//stream_if.data = 0;
//nbytes = 0;

//rst_n = 0;
//repeat (4) @(posedge clk);
//rst_n = 1;
//@(posedge clk);

//drive_bytes(test_str);

//repeat (20) @(posedge clk);

//$display("[%0t] done, fed %0d bytes", $time, nbytes);
//$finish;
//end

  logic clk = 0; //new uvm tb
  always #5 clk = ~clk;

  logic rst = 1;
  initial begin
    repeat (4) @(posedge clk);
    rst = 0;
  end

  argus_if #(.MATCH_W(4), .STATE_W(6)) ai(.clk(clk)); //flat
  assign ai.rst = rst;

  byte_stream bs(.clk(clk));
  match_out match(.clk(clk));

  assign bs.valid = ai.bs_valid;
  assign bs.data = ai.bs_data;
  assign ai.bs_ready = bs.ready;

  assign ai.match_valid = match.match_valid;
  assign ai.match_id = match.match_id;
  assign ai.match_state = match.current_state;

  argus_top #( //absolute paths
    .trans_mem("C:/Vivado/Argus/scripts/transition.mem"),
    .match_mem("C:/Vivado/Argus/scripts/match.mem"),
    .POLICY(2)
  ) dut (
    .clk(clk),
    .rst(rst),
    .bs(bs),
    .match(match),
    .hits(ai.hits),
    .misses(ai.misses),
    .ready(ai.ready)
  );

  initial begin
    uvm_config_db #(virtual argus_if)::set(null, "uvm_test_top.*", "vif", ai);
    run_test("directed_test"); //+UVM_TESTNAME = rand_test
  end
  
endmodule
