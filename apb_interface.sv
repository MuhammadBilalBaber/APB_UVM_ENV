//------------------------------------------------------------------------------
// APB interface
//
// Parameterized on address and data width so that a single interface
// definition can serve every APB instance in the testbench. Each parameter
// combination is a distinct SystemVerilog type, which is what keeps the
// virtual-interface handles of two differently sized agents from being mixed up.
//------------------------------------------------------------------------------

interface apb_interface #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32
) (
  input logic pclk,
  input logic presetn
);

  logic [ADDR_WIDTH-1:0] paddr;
  logic                  psel;
  logic                  penable;
  logic                  pwrite;
  logic [DATA_WIDTH-1:0] pwdata;
  logic [DATA_WIDTH-1:0] prdata;
  logic                  pready;
  logic                  pslverr;

  // Requester (master) view: outputs are driven in the NBA region of the
  // clock edge, inputs are sampled just before it, so the driver can never
  // race with the DUT.
  clocking mst_cb @(posedge pclk);
    default input #1step output #0;
    output paddr, psel, penable, pwrite, pwdata;
    input  prdata, pready, pslverr;
  endclocking

  // Passive view used by the monitor.
  clocking mon_cb @(posedge pclk);
    default input #1step;
    input paddr, psel, penable, pwrite, pwdata, prdata, pready, pslverr;
  endclocking

  modport mst_mp (clocking mst_cb, input pclk, input presetn);
  modport mon_mp (clocking mon_cb, input pclk, input presetn);

`ifndef APB_NO_ASSERTIONS

  wire setup_phase  = psel && !penable;
  wire access_phase = psel && penable;

  // A SETUP phase always lasts exactly one cycle and is followed by ACCESS.
  property p_setup_to_access;
    @(posedge pclk) disable iff (!presetn) setup_phase |=> access_phase;
  endproperty

  // PENABLE is only ever asserted together with PSEL.
  property p_penable_implies_psel;
    @(posedge pclk) disable iff (!presetn) penable |-> psel;
  endproperty

  // Control and payload must hold still for the whole ACCESS phase, i.e. while
  // the completer is inserting wait states.
  property p_stable_during_wait;
    @(posedge pclk) disable iff (!presetn)
      (access_phase && !pready) |=> ($stable(paddr) && $stable(pwrite) &&
                                     $stable(pwdata) && $stable(psel) && $stable(penable));
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
    else $error("APB_IF: SETUP phase was not followed by an ACCESS phase");
  a_penable_implies_psel: assert property (p_penable_implies_psel)
    else $error("APB_IF: PENABLE asserted while PSEL is low");
  a_stable_during_wait  : assert property (p_stable_during_wait)
    else $error("APB_IF: control/payload changed during a wait state");
  a_pready_in_access    : assert property (p_pready_in_access)
    else $error("APB_IF: PREADY asserted outside of an ACCESS phase");
  a_pslverr_with_pready : assert property (p_pslverr_with_pready)
    else $error("APB_IF: PSLVERR asserted without PREADY");

`endif

endinterface : apb_interface
