//------------------------------------------------------------------------------
// APB protocol checker.
//
// Kept in its own module rather than inline in the interface so the same
// assertions can be reused: apb_interface instantiates it for the UVM
// environment, and a plain-SystemVerilog testbench can instantiate it directly
// on raw signals.
//------------------------------------------------------------------------------

module apb_protocol_checker #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32
) (
  input logic                  pclk,
  input logic                  presetn,
  input logic [ADDR_WIDTH-1:0] paddr,
  input logic                  psel,
  input logic                  penable,
  input logic                  pwrite,
  input logic [DATA_WIDTH-1:0] pwdata,
  input logic [DATA_WIDTH-1:0] prdata,
  input logic                  pready,
  input logic                  pslverr
);

  wire setup_phase  = psel && !penable;
  wire access_phase = psel && penable;

  // A SETUP phase lasts exactly one cycle and is followed by ACCESS.
  property p_setup_to_access;
    @(posedge pclk) disable iff (!presetn) setup_phase |=> access_phase;
  endproperty

  // PENABLE is only ever asserted together with PSEL.
  property p_penable_implies_psel;
    @(posedge pclk) disable iff (!presetn) penable |-> psel;
  endproperty

  // Control and payload hold still while the completer inserts wait states.
  property p_stable_during_wait;
    @(posedge pclk) disable iff (!presetn)
      (access_phase && !pready) |=> ($stable(paddr) && $stable(pwrite) &&
                                     $stable(pwdata) && $stable(psel) &&
                                     $stable(penable));
  endproperty

  // PREADY is only meaningful during an ACCESS phase.
  property p_pready_in_access;
    @(posedge pclk) disable iff (!presetn) pready |-> access_phase;
  endproperty

  // PSLVERR is only valid on a completing transfer.
  property p_pslverr_with_pready;
    @(posedge pclk) disable iff (!presetn) (access_phase && pslverr) |-> pready;
  endproperty

  a_setup_to_access     : assert property (p_setup_to_access)
    else $error("APB: SETUP phase was not followed by an ACCESS phase");
  a_penable_implies_psel: assert property (p_penable_implies_psel)
    else $error("APB: PENABLE asserted while PSEL is low");
  a_stable_during_wait  : assert property (p_stable_during_wait)
    else $error("APB: control/payload changed during a wait state");
  a_pready_in_access    : assert property (p_pready_in_access)
    else $error("APB: PREADY asserted outside of an ACCESS phase");
  a_pslverr_with_pready : assert property (p_pslverr_with_pready)
    else $error("APB: PSLVERR asserted without PREADY");

endmodule : apb_protocol_checker
