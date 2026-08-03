`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Rishi Bala
// 
// Create Date: 08/03/2026 06:21:10 PM
// Design Name: 
// Module Name: argus_tb_pkg
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


//module argus_tb_pkg(

//    );
//endmodule

`include "uvm_macros.svh"

package argus_tb_pkg;

import uvm_pkg::*;

`uvm_analysis_imp_decl(_bytes)
`uvm_analysis_imp_decl(_matches)

class ac_byte_item extends uvm_sequence_item; //transactions
  `uvm_object_utils(ac_byte_item)
  rand logic [7:0] data;

  function new(string name = "ac_byte_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("0x%02x('%c')", data, data);
  endfunction
endclass

class ac_match_item extends uvm_object;
  `uvm_object_utils(ac_match_item)
  logic [3:0] match_id;
  int unsigned byte_cnt; //byte cnt when match fired

  function new(string name = "ac_match_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("id=%0d byte_cnt=%0d", match_id, byte_cnt);
  endfunction
endclass




typedef uvm_sequencer #(ac_byte_item) ac_sequencer; //sequencet



class ac_driver extends uvm_driver #(ac_byte_item); //driver
  `uvm_component_utils(ac_driver)
  virtual argus_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual argus_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "driver: no vif in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    ac_byte_item req;
    vif.bs_valid = 0;
    vif.bs_data = 0;
    while (vif.rst) @(posedge vif.clk);
    @(posedge vif.clk);
    forever begin
      seq_item_port.get_next_item(req);
      drive(req);
      seq_item_port.item_done();
    end
  endtask

  task drive(ac_byte_item item); //handshake occurs at the posedge where both are high; DUT captures there.
  //combinational, sample at posedge active
    @(posedge vif.clk); #1;
    vif.bs_valid = 1;
    vif.bs_data = item.data;
    @(posedge vif.clk);
    while (!vif.bs_ready) @(posedge vif.clk);
    #2;
    vif.bs_valid = 0;
  endtask
endclass


class ac_monitor extends uvm_monitor; //monitor
  `uvm_component_utils(ac_monitor)
  virtual argus_if vif;

  uvm_analysis_port #(ac_byte_item) bytes_ap;
  uvm_analysis_port #(ac_match_item) matches_ap;

  int byte_cnt;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    bytes_ap = new("bytes_ap", this);
    matches_ap = new("matches_ap", this);
    if (!uvm_config_db #(virtual argus_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "monitor: no vif in config_db")
    byte_cnt = 0;
  endfunction

  task run_phase(uvm_phase phase); //single loop to check byte stream then match
    forever begin
      @(posedge vif.clk);

      if (vif.bs_valid && vif.bs_ready) begin
        ac_byte_item b;
        b = ac_byte_item::type_id::create("b");
        b.data = vif.bs_data;
        bytes_ap.write(b);
        byte_cnt++;
      end

      if (vif.match_valid) begin
        ac_match_item m;
        m = ac_match_item::type_id::create("m");
        m.match_id = vif.match_id;
        m.byte_cnt = byte_cnt;
        matches_ap.write(m);
        `uvm_info("MON", $sformatf("match id=%0d byte_cnt=%0d (idx=%0d)",
          m.match_id, m.byte_cnt, m.byte_cnt - 1), UVM_LOW)
      end
    end
  endtask
endclass

class ac_scoreboard extends uvm_scoreboard; //scoreboard
  `uvm_component_utils(ac_scoreboard)

  uvm_analysis_imp_bytes #(ac_byte_item, ac_scoreboard) bytes_imp;
  uvm_analysis_imp_matches #(ac_match_item, ac_scoreboard) matches_imp;

  byte byte_buf[$];
  ac_match_item match_q[$];
  string patterns[int]; //match_id -> pattern string

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    bytes_imp = new("bytes_imp", this);
    matches_imp = new("matches_imp", this);
    //add entries here if you add patterns to patterns.txt
    patterns[5] = "cmd.exe";
    patterns[6] = "attack";
    patterns[7] = "malware";
  endfunction

  function void write_bytes(ac_byte_item item);
    byte_buf.push_back(byte'(item.data));
  endfunction

  function void write_matches(ac_match_item item);
    ac_match_item copy;
    copy = ac_match_item::type_id::create("copy");
    copy.match_id = item.match_id;
    copy.byte_cnt = item.byte_cnt;
    match_q.push_back(copy);
  endfunction

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info("SB", $sformatf("stream=%0d bytes  matches=%0d",
      byte_buf.size(), match_q.size()), UVM_LOW)
    check_false_positives();
    check_false_negatives();
  endfunction

endpackage