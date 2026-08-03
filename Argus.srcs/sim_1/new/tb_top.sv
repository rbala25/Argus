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

byte_stream stream_if(clk, rst_n);
mem mem_if(clk, rst_n); //interfaces
match_out match_if(clk, rst_n);

ac_matcher #(.MATCH_FILE("C:/Vivado/Argus/scripts/match.mem")) matcher(
  .clk(clk),
  .rst_n(rst_n),
  .stream(stream_if),
  .mem_bus(mem_if),
  .mout(match_if)
);

slow_mem #(.latency(5), .mem_file("C:/Vivado/Argus/scripts/transition.mem")) model(
  .clk(clk),
  .rst_n(rst_n),
  .mem_bus(mem_if)
);
string test_str = "attack detected, running cmd.exe, found malware";

task automatic drive_bytes(input string s);
    for (int i = 0; i < s.len(); i++) begin
      @(posedge clk);
      stream_if.data = s[i];
      stream_if.valid = 1;
      while (!stream_if.ready) @(posedge clk);
    end
    @(posedge clk);
    stream_if.valid = 0;
    stream_if.data = 0;
endtask

int nbytes; //monitor, byte count
always @(posedge clk) begin
if (rst_n) begin
  if (match_if.match_valid)
    $display("[%0t] MATCH id=%0d state=%0d after byte index %0d",
             $time, match_if.match_id, match_if.current_state, nbytes-1);
  if (stream_if.valid && stream_if.ready)
    nbytes++;
end
end

//run
initial begin
stream_if.valid = 0;
stream_if.data = 0;
nbytes = 0;

rst_n = 0;
repeat (4) @(posedge clk);
rst_n = 1;
@(posedge clk);

drive_bytes(test_str);

repeat (20) @(posedge clk);

$display("[%0t] done, fed %0d bytes", $time, nbytes);
$finish;
end

  
endmodule
