//------------------------------------------------------------------------------
// Testbench top.
//
// Elaborates one interface + completer pair per entry in apb_param_pkg and
// publishes each virtual interface under its own configuration database key.
// Adding another APB instance is a single line in apb_param_pkg.
//------------------------------------------------------------------------------

`include "uvm_macros.svh"

module apb_tb_top;

  import uvm_pkg::*;
  import apb_pkg::*;
  import apb_param_pkg::*;

  localparam time CLK_PERIOD = 10ns;

  bit   pclk;
  logic presetn;

  always #(CLK_PERIOD / 2) pclk = ~pclk;

  initial begin
    presetn = 1'b0;
    // Released off the active edge so the completer's asynchronous reset can
    // never race with a clock edge.
    repeat (5) @(negedge pclk);
    presetn = 1'b1;
  end

  for (genvar i = 0; i < NUM_APB; i++) begin : apb_inst

    apb_interface #(
      .ADDR_WIDTH (APB_ADDR_W[i]),
      .DATA_WIDTH (APB_DATA_W[i])
    ) apb_intf (
      .pclk    (pclk),
      .presetn (presetn)
    );

    apb_s #(
      .ADDR_WIDTH (APB_ADDR_W[i]),
      .DATA_WIDTH (APB_DATA_W[i]),
      .MEM_DEPTH  (APB_MEM_DEPTH[i])
    ) apb_completer (
      .pclk    (pclk),
      .presetn (presetn),
      .paddr   (apb_intf.paddr),
      .psel    (apb_intf.psel),
      .penable (apb_intf.penable),
      .pwrite  (apb_intf.pwrite),
      .pwdata  (apb_intf.pwdata),
      .prdata  (apb_intf.prdata),
      .pready  (apb_intf.pready),
      .pslverr (apb_intf.pslverr)
    );

    // The virtual interface type is specialized per instance, so this set() is
    // type-checked against the matching apb_env specialization on the get side.
    initial begin
      uvm_config_db #(virtual apb_interface #(APB_ADDR_W[i], APB_DATA_W[i]))::set(
        null, "*", apb_vif_key(i), apb_intf);
    end

  end : apb_inst

  initial begin
    $timeformat(-9, 0, " ns", 10);
    // The #0 lets every apb_inst[*] initial block publish its virtual
    // interface before the test's build_phase goes looking for it.
    #0;
    run_test();
  end

endmodule : apb_tb_top
