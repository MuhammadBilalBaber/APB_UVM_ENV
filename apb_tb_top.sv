

`include "uvm_macros.svh"
import uvm_pkg::*;

import apb_param_pkg::*;

module apb_tb_top;


  // Clock and reset signal

  bit clock;
  bit reset;

  always #5 clock = ~clock;

  initial begin
    reset = 0;
    @(posedge clock);
    @(posedge clock);
    reset = 1;
  end

  // Interface

  apb_interface #(.ADDR_WIDTH(ADDR_W), .DATA_WIDTH(DATA_W)) apb_intf(clock, reset);

  // APB DUT

  apb_s #(.ADDR_WIDTH(ADDR_W), .DATA_WIDTH(DATA_W)) apb_s(
     .pclk     (clock),
     .presetn  (reset),
     .psel     (apb_intf.psel),     
     .paddr    (apb_intf.paddr),
     .pwdata   (apb_intf.pwdata),
     .pwrite   (apb_intf.pwrite),
     .pready   (apb_intf.pready),
     .penable  (apb_intf.penable),
     .prdata   (apb_intf.prdata),
     .pslverr  (apb_intf.pslverr)
  );

  initial begin
    uvm_config_db#(virtual apb_interface)::set(null,"uvm_test_top.apb_env.apb_agnt.*","apb_intf",apb_intf);
  end 
