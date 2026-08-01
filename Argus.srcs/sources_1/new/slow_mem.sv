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

always_ff @(posedge clk) begin
if (!rst_n) begin
  fsm <= s_idle;
  cnt <= 0;
  addr_q <= 0;
  row_q <= 0;
  mem_bus.ack <= 0;
end else begin
  case (fsm)
    s_idle: begin
      mem_bus.ack <= 0;
      if (mem_bus.req) begin
        addr_q <= mem_bus.state_addr;
        cnt <= 1;
        fsm <= s_wait;
      end
    end
    s_wait: begin
      if (cnt == latency) begin
        row_q <= build_row(addr_q);
        mem_bus.ack <= 1;
        fsm <= s_done;
      end else begin
        cnt <= cnt + 1;
      end
    end
    s_done: begin
      //hold ack and data until the matcher takes it and drops req
      if (!mem_bus.req) begin
        mem_bus.ack <= 0;
        fsm <= s_idle;
      end
    end
  endcase
end
end

assign mem_bus.row_data = row_q;

endmodule
