//------------------------------------------------------------------------------
// Attaches the protocol checker to every APB completer instance.
//
// The bind targets apb_s rather than apb_interface because an interface may not
// contain a module instantiation. The completer's pins carry exactly the same
// signals as the interface, so the checks are equivalent, and binding to the
// definition means every instance is covered with its own widths without the
// testbench naming any of them.
//
// Compile with APB_NO_ASSERTIONS defined to leave the checkers out.
//------------------------------------------------------------------------------

`ifndef APB_NO_ASSERTIONS

bind apb_s apb_protocol_checker #(
  .ADDR_WIDTH (ADDR_WIDTH),
  .DATA_WIDTH (DATA_WIDTH)
) apb_checker_inst (
  .pclk    (pclk),
  .presetn (presetn),
  .paddr   (paddr),
  .psel    (psel),
  .penable (penable),
  .pwrite  (pwrite),
  .pwdata  (pwdata),
  .prdata  (prdata),
  .pready  (pready),
  .pslverr (pslverr)
);

`endif
